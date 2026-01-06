import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/product.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/adapters.dart';

class HiveService {
  static const _keyName = 'hive_encryption_key';
  static final _secureStorage = const FlutterSecureStorage();

  /// Initialize Hive, register adapters and open boxes with encryption.
  static Future<void> init() async {
    await Hive.initFlutter();
    registerAdapters();

    // Ensure an encryption key is stored
    final key = await _getOrCreateKey();
    final cipher = HiveAesCipher(key);

    // Open boxes
    await Hive.openBox('users', encryptionCipher: cipher);
    await Hive.openBox('products', encryptionCipher: cipher);
    await Hive.openBox('favorites', encryptionCipher: cipher);
    await Hive.openBox('cart', encryptionCipher: cipher);
    await Hive.openBox('history', encryptionCipher: cipher);
    await Hive.openBox('app', encryptionCipher: cipher); // small app prefs

    // Prepopulate demo users if none
    final usersBox = Hive.box('users');
    if (usersBox.isEmpty) {
      usersBox.put('u_admin',
          User(id: 'u_admin', name: 'Admin', role: 'admin', avatarPath: ''));
      usersBox.put('u_manager',
          User(id: 'u_manager', name: 'Manager', role: 'manager', avatarPath: ''));
      usersBox.put('u_user',
          User(id: 'u_user', name: 'Visitor', role: 'user', avatarPath: ''));
      // set default current user
      final appBox = Hive.box('app');
      appBox.put('currentUserId', 'u_user');
    }

    // Prepopulate test flights if none
    final flightsBox = Hive.box('products');
    if (flightsBox.isEmpty) {
      flightsBox.put('flight_1', Flight(
        id: 'flight_1',
        flightNumber: 'BA101',
        departureCity: 'New York',
        arrivalCity: 'London',
        departureTime: '10:00',
        arrivalTime: '22:00',
        price: 299.99,
        availableSeats: 45,
        airline: 'British Airways',
        isLiked: false,
      ));
      flightsBox.put('flight_2', Flight(
        id: 'flight_2',
        flightNumber: 'LH202',
        departureCity: 'Berlin',
        arrivalCity: 'Paris',
        departureTime: '09:30',
        arrivalTime: '11:15',
        price: 449.99,
        availableSeats: 32,
        airline: 'Lufthansa',
        isLiked: false,
      ));
      flightsBox.put('flight_3', Flight(
        id: 'flight_3',
        flightNumber: 'AF303',
        departureCity: 'Paris',
        arrivalCity: 'Rome',
        departureTime: '14:00',
        arrivalTime: '16:45',
        price: 199.99,
        availableSeats: 58,
        airline: 'Air France',
        isLiked: false,
      ));
    }

  }

  static Future<Uint8List> _getOrCreateKey() async {
    try {
      final stored = await _secureStorage.read(key: _keyName);
      if (stored != null) {
        try {
          return base64Decode(stored);
        } catch (e) {
          if (kDebugMode) print('HiveService: failed to decode stored key: $e');
          // Stored value is invalid/corrupted — remove and recreate
          try {
            await _secureStorage.delete(key: _keyName);
          } catch (_) {}
        }
      }
    } catch (e) {
      if (kDebugMode) print('HiveService: error reading secure storage: $e');
      // In case of platform/storage errors, attempt to delete and recreate
      try {
        await _secureStorage.delete(key: _keyName);
      } catch (_) {}
    }

    // generate 32 bytes key
    final rnd = Random.secure();
    final key = List<int>.generate(32, (_) => rnd.nextInt(256));
    final encoded = base64Encode(Uint8List.fromList(key));
    try {
      await _secureStorage.write(key: _keyName, value: encoded);
    } catch (e) {
      if (kDebugMode) print('HiveService: failed to write key to secure storage: $e');
      // Even if we fail to persist the key, return it to allow Hive to operate in-memory
    }
    return Uint8List.fromList(key);
  }

  static Uint8List generateNewKey() {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
  }

  static Future<String> tryOpenWithKey(Uint8List key) async {
    const target = 'products';

    // 1. Загружаем правильный ключ
    final stored = await _secureStorage.read(key: _keyName);
    if (stored == null) return 'No stored key available.';
    final correctKey = base64Decode(stored);
    final correctCipher = HiveAesCipher(correctKey);

    final wrongCipher = HiveAesCipher(key);

    bool wasOpen = Hive.isBoxOpen(target);

    try {
      // 2. Закрываем бокс если он открыт
      if (wasOpen) await Hive.box(target).close();

      // 3. Пробуем открыть с неверным ключом
      await Hive.openBox(target, encryptionCipher: wrongCipher);
      final wrongBox = Hive.box(target);

      // 4. Если бокс пустой – создаем тестовую запись
      if (wrongBox.isEmpty) {
        // Создаем запись, гарантированно имеющую payload
        await wrongBox.put("_probe", {
          "test": "value",
          "id": 123,
          "nested": {"x": 1}
        });
      }

      try {
        // 5. Пробуем прочитать реальный payload (гарантированно упадет)
        final firstValue = wrongBox.getAt(0);

        // Дополнительная проверка: попробовать использовать данные
        if (firstValue is Map) {
          // доступ к полю → 100% расшифровка + ошибка
          final t = firstValue["test"];
        }

        // Если дошли сюда – что-то невероятное произошло
        return 'Unexpected: decrypted using wrong key without error';
      } catch (readError) {
        return 'Failed to decrypt using provided key:\n$readError';
      }
    } catch (openError) {
      return 'Failed to open with provided key:\n$openError';
    } finally {
      // 6. Восстанавливаем правильное состояние бокса
      try {
        if (Hive.isBoxOpen(target)) await Hive.box(target).close();
      } catch (_) {}

      await Hive.openBox(target, encryptionCipher: correctCipher);
    }
  }

  /// Compact (compress) a box by name
  static Future<void> compactBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).compact();
    } else {
      // open temporarily with a safe key retrieval (regenerates if corrupted)
      final key = await _getOrCreateKey();
      final cipher = HiveAesCipher(key);
      final box = await Hive.openBox(name, encryptionCipher: cipher);
      await box.compact();
      await box.close();
    }
  }

  /// Check encryption status: verify that key is stored and accessible
  static Future<String> checkEncryptionStatus() async {
    final stored = await _secureStorage.read(key: _keyName);
    if (stored == null) {
      return 'No encryption key found!';
    }
    try {
      final decoded = base64Decode(stored);
      return 'Encryption key is securely stored in flutter_secure_storage.\n'
          'Key size: ${decoded.length} bytes\n'
          'Hive boxes are encrypted with AES cipher.\n'
          'All data in products, favorites, cart, history, users, and app boxes are protected.';
    } catch (e) {
      return 'Error reading encryption key: $e';
    }
  }
}

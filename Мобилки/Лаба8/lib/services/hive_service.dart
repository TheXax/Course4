import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/product.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/adapters.dart';

class HiveService { //инициализация Hive,  открытие коробок, работа с шифрованием
  static const _keyName = 'hive_encryption_key'; //
  static final _secureStorage = const FlutterSecureStorage(); //8    Экземпляр безопасного хранилища

  //инициализация Hive.
  static Future<void> init() async {
    await Hive.initFlutter();
    registerAdapters(); //Регистрирует Hive TypeAdapter’ы

    //шифрование
    final key = await _getOrCreateKey(); //пытается достать ключ из SecureStorage, если нет, то генерирует
    final cipher = HiveAesCipher(key); //Бинарный ключ → объект шифра AES-256, который Hive использует для шифрования/дешифрования записи

    //открытие боксов с шифрованием
    await Hive.openBox('users', encryptionCipher: cipher);
    await Hive.openBox('products', encryptionCipher: cipher);
    await Hive.openBox('favorites', encryptionCipher: cipher);
    await Hive.openBox('cart', encryptionCipher: cipher);
    await Hive.openBox('history', encryptionCipher: cipher);
    await Hive.openBox('app', encryptionCipher: cipher); // small app prefs

    // Задание 1
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

    // задание 2
    final productsBox = Hive.box('products');
    if (productsBox.isEmpty) {
      productsBox.put('tour_1', Product(
        id: 'tour_1',
        imagePath: '',
        price: 299.99,
        location: 'Rome, Italy',
        reviewsCount: 42,
        description: 'Historic Rome City Tour',
        isLiked: false,
      ));
      productsBox.put('tour_2', Product(
        id: 'tour_2',
        imagePath: '',
        price: 449.99,
        location: 'Florence, Italy',
        reviewsCount: 38,
        description: 'Florence Renaissance & Art',
        isLiked: false,
      ));
      productsBox.put('tour_3', Product(
        id: 'tour_3',
        imagePath: '',
        price: 199.99,
        location: 'Venice, Italy',
        reviewsCount: 55,
        description: 'Venice Canal & Bridge Walk',
        isLiked: false,
      ));
    }

  }

  static Future<Uint8List> _getOrCreateKey() async { //создание или получение защищённого ключа
    final stored = await _secureStorage.read(key: _keyName);
    if (stored != null) {
      return base64Decode(stored); //Пытаемся прочитать ключ. Если есть → расшифровываем из base64 → возвращаем
    }

    // генерация 32bit ключа
    final rnd = Random.secure();
    final key = List<int>.generate(32, (_) => rnd.nextInt(256));
    final encoded = base64Encode(Uint8List.fromList(key)); //кодирование
    await _secureStorage.write(key: _keyName, value: encoded);
    return Uint8List.fromList(key);
  }

  static Uint8List generateNewKey() { //создание нового случайного AES ключа
    final rnd = Random.secure(); //используется для проверки неправильного ключа
    return Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
  }

  // 9 Проверка неверного ключа
  static Future<String> tryOpenWithKey(Uint8List key) async {
    const target = 'products';

    // 1. Загружаем правильный ключ
    final stored = await _secureStorage.read(key: _keyName);
    if (stored == null) return 'No stored key available.';
    final correctKey = base64Decode(stored); //читаем сохранённый рабочий ключ
    final correctCipher = HiveAesCipher(correctKey); //верный

    final wrongCipher = HiveAesCipher(key); //неверный

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
        // 5. Пробуем прочитать реальный payload (гарантированно упадёт)
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

  //10   Сжатие базы
  static Future<void> compactBox(String name) async { //Если бокс открыт, то вызываем compact() , который удаляет "дырки" от старых удалённых записей и уменьшает размер файла
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).compact();
    } else {
      // открываем с правильным ключом
      final key = base64Decode((await _secureStorage.read(key: _keyName))!);
      final cipher = HiveAesCipher(key);
      final box = await Hive.openBox(name, encryptionCipher: cipher);
      await box.compact();
      await box.close();
    }
  }

  //8  проверка наличия ключа
  static Future<String> checkEncryptionStatus() async {
    final stored = await _secureStorage.read(key: _keyName);
    if (stored == null) {
      return 'No encryption key found!';
    }
    try { //пробуем расшифровать
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

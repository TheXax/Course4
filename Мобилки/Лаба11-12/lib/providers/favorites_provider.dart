import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/favorite.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';

/// Provider для управления избранным (с Firestore + Hive cache)
class FavoritesProvider extends ChangeNotifier {
  final List<Favorite> _favorites = [];
  final FirebaseService _fs = FirebaseService(); //подписка на изменения
  StreamSubscription? _subscription; //подписку на Firestore

  List<Favorite> get favorites => _favorites;
  int get favoritesCount => _favorites.length;

  FavoritesProvider() {
    _loadFavorites();
    _subscribeFirestore();
  }

  //загружает данные из локальной БД
  void _loadFavorites() {
    try {
      final favoritesBox = Hive.box('favorites');
      _favorites.clear();
      for (var key in favoritesBox.keys) {
        final favorite = favoritesBox.get(key) as Favorite;
        _favorites.add(favorite);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  void _subscribeFirestore() {
    try {
      //подписка на коллекцию
      _subscription = _fs.collectionStream('favorites').listen((snapshot) async {
        final box = Hive.box('favorites');
        _favorites.clear();
        for (final doc in snapshot.docs) { //проходимся по документам из Firestore
          final data = doc.data() as Map<String, dynamic>; //берём данные
          data['id'] = doc.id; //добавляем id
          final fav = Favorite.fromMap(data);
          _favorites.add(fav);
          try {
            await box.put(doc.id, fav); //Обновляем Hive кеш, чтобы данные были доступны офлайн
          } catch (_) {}
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error subscribing to favorites: $e');
    }
  }

  Future<void> addFavorite(String productId, String productName) async {
    try {
      final fav = Favorite(productId: productId, productName: productName);
      final docRef = await _fs.addDocument('favorites', fav.toMap());
      fav.productId = fav.productId; //получаем id
      final box = Hive.box('favorites');
      await box.put(docRef.id, fav);
      _favorites.add(fav);
      try {
        //логируем событие в аналитику
        await AnalyticsService.instance.logEvent('add_to_favorites', parameters: {'productId': productId});
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
    }
  }

  Future<void> removeFavorite(String productId) async {
    try {
      final box = Hive.box('favorites');
      final keysToRemove = <String>[];

      for (var key in box.keys) {
        final fav = box.get(key) as Favorite;
        if (fav.productId == productId) keysToRemove.add(key as String);
      }

      for (var key in keysToRemove) {
        try {
          await _fs.deleteDocument('favorites', key); //удаляем из Hive и Firestore
        } catch (_) {}
        box.delete(key);
      }

      //удаляем из памяти
      _favorites.removeWhere((f) => f.productId == productId);
      try {
        await AnalyticsService.instance.logEvent('remove_from_favorites', parameters: {'productId': productId});
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }

  bool isFavorite(String productId) {
    return _favorites.any((f) => f.productId == productId);
  }

  Future<void> clearFavorites() async {
    try {
      final box = Hive.box('favorites');
      for (var key in box.keys) {
        try {
          await _fs.deleteDocument('favorites', key as String);
        } catch (_) {}
      }
      box.clear();
      _favorites.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }

  @override
  void dispose() { //отменяем подписку на Firestore, предотвращая утечку памяти
    _subscription?.cancel();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/favorite.dart';

//Provider для управления избранным
class FavoritesProvider extends ChangeNotifier {
  final List<Favorite> _favorites = [];

  List<Favorite> get favorites => _favorites;
  int get favoritesCount => _favorites.length;

  FavoritesProvider() {
    _loadFavorites();
  }

  //Загрузить все избранные товары
  void _loadFavorites() { //вызывается только внутри провайдера
    try {
      final favoritesBox = Hive.box('favorites');
      _favorites.clear(); //очищаем список в памяти, чтобы избежать дубликатов
      for (var key in favoritesBox.keys) {
        final favorite = favoritesBox.get(key) as Favorite;
        _favorites.add(favorite);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  //Добавить товар в избранное
  void addFavorite(String productId, String productName) {
    try {
      final favoritesBox = Hive.box('favorites');
      final favorite = Favorite(productId: productId, productName: productName);
      final key = '${productId}_${DateTime.now().millisecondsSinceEpoch}'; //генерируем ключ
      favoritesBox.put(key, favorite);
      _favorites.add(favorite);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
    }
  }

  //Удалить товар из избранного
  void removeFavorite(String productId) {
    try {
      final favoritesBox = Hive.box('favorites');
      final keysToRemove = <String>[];

      for (var key in favoritesBox.keys) {
        final favorite = favoritesBox.get(key) as Favorite;
        if (favorite.productId == productId) {
          keysToRemove.add(key as String); //добавляем в список на удаление
        }
      }

      for (var key in keysToRemove) {
        favoritesBox.delete(key);
      }

      _favorites.removeWhere((f) => f.productId == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }

  //Проверить, находится ли товар в избранном
  bool isFavorite(String productId) {
    return _favorites.any((f) => f.productId == productId);
  }

  //Очистить все избранные
  void clearFavorites() {
    try {
      final favoritesBox = Hive.box('favorites');
      favoritesBox.clear();
      _favorites.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }
}

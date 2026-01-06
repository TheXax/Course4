import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart.dart';

/// Provider для управления корзиной
class CartProvider extends ChangeNotifier {
  final List<Cart> _cartItems = [];

  List<Cart> get cartItems => _cartItems;
  int get cartCount => _cartItems.length;

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  CartProvider() {
    _loadCart();
  }

  /// Загрузить товары из корзины
  void _loadCart() {
    try {
      final cartBox = Hive.box('cart');
      _cartItems.clear();
      for (var key in cartBox.keys) {
        final item = cartBox.get(key) as Cart;
        _cartItems.add(item);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  /// Добавить товар в корзину
  void addToCart(String productId, String productName, double price) {
    try {
      final cartBox = Hive.box('cart');
      final existing = _cartItems.firstWhere(
        (item) => item.productId == productId,
        orElse: () => Cart(productId: '', productName: '', price: 0, quantity: 0),
      );

      if (existing.productId.isEmpty) {
        // Новый товар
        final cartItem = Cart(
          productId: productId,
          productName: productName,
          price: price,
          quantity: 1,
        );
        final key = '${productId}_${DateTime.now().millisecondsSinceEpoch}';
        cartBox.put(key, cartItem);
        _cartItems.add(cartItem);
      } else {
        // Товар уже в корзине - увеличить количество
        existing.quantity += 1;
        final key = _cartItems.indexOf(existing);
        cartBox.putAt(key, existing);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  /// Удалить товар из корзины
  void removeFromCart(String productId) {
    try {
      final cartBox = Hive.box('cart');
      final keysToRemove = <String>[];

      for (var key in cartBox.keys) {
        final item = cartBox.get(key) as Cart;
        if (item.productId == productId) {
          keysToRemove.add(key as String);
        }
      }

      for (var key in keysToRemove) {
        cartBox.delete(key);
      }

      _cartItems.removeWhere((item) => item.productId == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  /// Обновить количество товара
  void updateQuantity(String productId, int quantity) {
    try {
      if (quantity <= 0) {
        removeFromCart(productId);
        return;
      }

      final cartBox = Hive.box('cart');
      final item = _cartItems.firstWhere((i) => i.productId == productId);
      item.quantity = quantity;

      final index = _cartItems.indexOf(item);
      cartBox.putAt(index, item);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  /// Очистить корзину
  void clearCart() {
    try {
      final cartBox = Hive.box('cart');
      cartBox.clear();
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  /// Получить количество товара в корзине
  int getQuantity(String productId) {
    try {
      return _cartItems.firstWhere((i) => i.productId == productId).quantity;
    } catch (e) {
      return 0;
    }
  }

  /// Проверить, находится ли товар в корзине
  bool isInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }
}

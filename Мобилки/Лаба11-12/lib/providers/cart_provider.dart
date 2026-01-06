import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart.dart';
import '../services/firebase_service.dart';

/// Provider для управления корзиной (с Firestore + Hive cache)
class CartProvider extends ChangeNotifier {
  final List<Cart> _cartItems = [];
  final FirebaseService _fs = FirebaseService();
  StreamSubscription? _subscription;

  List<Cart> get cartItems => _cartItems;
  int get cartCount => _cartItems.length;

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  CartProvider() {
    _loadCart();
    _subscribeFirestore();
  }

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

  void _subscribeFirestore() {
    try {
      _subscription = _fs.collectionStream('cart').listen((snapshot) async {
        final box = Hive.box('cart');
        _cartItems.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final c = Cart.fromMap(data);
          _cartItems.add(c);
          try {
            await box.put(doc.id, c);
          } catch (_) {}
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error subscribing to cart: $e');
    }
  }

  Future<void> addToCart(String productId, String productName, double price) async {
    try {
      final existing = _cartItems.firstWhere(
        (item) => item.productId == productId,
        orElse: () => Cart(productId: '', productName: '', price: 0, quantity: 0),
      );

      if (existing.productId.isEmpty) {
        final cartItem = Cart(productId: productId, productName: productName, price: price, quantity: 1);
        final docRef = await _fs.addDocument('cart', cartItem.toMap());
        final box = Hive.box('cart');
        await box.put(docRef.id, cartItem);
        _cartItems.add(cartItem);
      } else {
        existing.quantity += 1;
        try {
          // update first matching doc in Firestore by searching cart collection for productId
          final snapshot = await _fs.collection('cart').where('productId', isEqualTo: productId).get();
          if (snapshot.docs.isNotEmpty) {
            final docId = snapshot.docs.first.id;
            await _fs.updateDocument('cart', docId, existing.toMap());
          }
        } catch (_) {}
        final box = Hive.box('cart');
        final index = _cartItems.indexOf(existing);
        box.putAt(index, existing);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      final box = Hive.box('cart');
      final keysToRemove = <String>[];

      for (var key in box.keys) {
        final item = box.get(key) as Cart;
        if (item.productId == productId) keysToRemove.add(key as String);
      }

      for (var key in keysToRemove) {
        try {
          await _fs.deleteDocument('cart', key);
        } catch (_) {}
        box.delete(key);
      }

      _cartItems.removeWhere((item) => item.productId == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(productId);
        return;
      }

      final item = _cartItems.firstWhere((i) => i.productId == productId);
      item.quantity = quantity;

      try {
        final snapshot = await _fs.collection('cart').where('productId', isEqualTo: productId).get();
        if (snapshot.docs.isNotEmpty) {
          final docId = snapshot.docs.first.id;
          await _fs.updateDocument('cart', docId, item.toMap());
        }
      } catch (_) {}

      final box = Hive.box('cart');
      final index = _cartItems.indexOf(item);
      box.putAt(index, item);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final box = Hive.box('cart');
      for (var key in box.keys) {
        try {
          await _fs.deleteDocument('cart', key as String);
        } catch (_) {}
      }
      box.clear();
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  int getQuantity(String productId) {
    try {
      return _cartItems.firstWhere((i) => i.productId == productId).quantity;
    } catch (e) {
      return 0;
    }
  }

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

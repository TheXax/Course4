import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../models/cart.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<LoadCart>(_onLoad);
    on<AddToCartEvent>(_onAdd);
    on<RemoveFromCartEvent>(_onRemove);
    on<UpdateQuantityEvent>(_onUpdate);
    on<ClearCartEvent>(_onClear);
  }

  Future<void> _onLoad(LoadCart event, Emitter<CartState> emit) async {
    try {
      final box = Hive.box('cart');
      final List<Cart> items = [];
      for (var key in box.keys) {
        items.add(box.get(key) as Cart);
      }
      emit(CartLoadSuccess(items));
    } catch (e) {
      emit(CartOperationFailure('Failed to load cart: $e'));
    }
  }

  Future<void> _onAdd(AddToCartEvent event, Emitter<CartState> emit) async {
    try {
      final box = Hive.box('cart');
      final items = <Cart>[];
      for (var key in box.keys) items.add(box.get(key) as Cart);

      final existing = items.firstWhere(
        (i) => i.productId == event.productId,
        orElse: () => Cart(productId: '', productName: '', price: 0, quantity: 0),
      );

      if (existing.productId.isEmpty) {
        final cartItem = Cart(
          productId: event.productId,
          productName: event.productName,
          price: event.price,
          quantity: 1,
        );
        final key = '${event.productId}_${DateTime.now().millisecondsSinceEpoch}';
        await box.put(key, cartItem);
      } else {
        existing.quantity += 1;
        final index = items.indexOf(existing);
        await box.putAt(index, existing);
      }
      add(LoadCart());
    } catch (e) {
      emit(CartOperationFailure('Failed to add to cart: $e'));
    }
  }

  Future<void> _onRemove(RemoveFromCartEvent event, Emitter<CartState> emit) async {
    try {
      final box = Hive.box('cart');
      final keysToRemove = <dynamic>[];
      for (var key in box.keys) {
        final item = box.get(key) as Cart;
        if (item.productId == event.productId) keysToRemove.add(key);
      }
      for (var k in keysToRemove) await box.delete(k);
      add(LoadCart());
    } catch (e) {
      emit(CartOperationFailure('Failed to remove from cart: $e'));
    }
  }

  Future<void> _onUpdate(UpdateQuantityEvent event, Emitter<CartState> emit) async {
    try {
      if (event.quantity <= 0) {
        add(RemoveFromCartEvent(event.productId));
        return;
      }
      final box = Hive.box('cart');
      final items = <Cart>[];
      for (var key in box.keys) items.add(box.get(key) as Cart);
      final item = items.firstWhere((i) => i.productId == event.productId);
      item.quantity = event.quantity;
      final idx = items.indexOf(item);
      await box.putAt(idx, item);
      add(LoadCart());
    } catch (e) {
      emit(CartOperationFailure('Failed to update quantity: $e'));
    }
  }

  Future<void> _onClear(ClearCartEvent event, Emitter<CartState> emit) async {
    try {
      final box = Hive.box('cart');
      await box.clear();
      emit(CartLoadSuccess([]));
    } catch (e) {
      emit(CartOperationFailure('Failed to clear cart: $e'));
    }
  }
}

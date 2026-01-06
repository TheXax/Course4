import '../models/cart.dart';

abstract class CartState {}

class CartInitial extends CartState {}

class CartLoadSuccess extends CartState {
  final List<Cart> items;
  CartLoadSuccess(this.items);

  double get totalPrice => items.fold(0.0, (s, i) => s + (i.price * i.quantity));
}

class CartOperationFailure extends CartState {
  final String message;
  CartOperationFailure(this.message);
}

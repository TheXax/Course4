abstract class CartEvent {}

class LoadCart extends CartEvent {}

class AddToCartEvent extends CartEvent {
  final String productId;
  final String productName;
  final double price;
  AddToCartEvent(this.productId, this.productName, this.price);
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;
  RemoveFromCartEvent(this.productId);
}

class UpdateQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;
  UpdateQuantityEvent(this.productId, this.quantity);
}

class ClearCartEvent extends CartEvent {}

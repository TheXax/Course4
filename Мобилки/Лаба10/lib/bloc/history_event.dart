abstract class HistoryEvent {}

class LoadHistory extends HistoryEvent {}

class AddPurchase extends HistoryEvent {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  AddPurchase(this.productId, this.productName, this.price, this.quantity);
}

class ClearHistoryEvent extends HistoryEvent {}

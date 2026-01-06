import 'package:hive/hive.dart';

class History extends HiveObject {
  String productId;
  String productName;
  double price;
  int quantity;
  DateTime purchaseDate;

  History({required this.productId, required this.productName, required this.price, required this.quantity, required this.purchaseDate});
}

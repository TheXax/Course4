import 'package:hive/hive.dart';

class Cart extends HiveObject {
  String productId;
  String productName;
  double price;
  int quantity;

  Cart({required this.productId, required this.productName, required this.price, required this.quantity});
}

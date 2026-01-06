import 'package:hive/hive.dart';

class Cart extends HiveObject {
  String productId;
  String productName;
  double price;
  int quantity;

  Cart({required this.productId, required this.productName, required this.price, required this.quantity});

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
      };

  //Метод преобразует объект Cart в Map, для сохранения в Hive, отправки в Firebase
  factory Cart.fromMap(Map<String, dynamic> map) => Cart(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.tryParse('${map['price']}') ?? 0.0,
        quantity: map['quantity'] is int ? map['quantity'] as int : int.tryParse('${map['quantity']}') ?? 0,
      );
}

import 'package:hive/hive.dart';

class History extends HiveObject {
  String productId;
  String productName;
  double price;
  int quantity;
  DateTime purchaseDate;

  History({required this.productId, required this.productName, required this.price, required this.quantity, required this.purchaseDate});

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'purchaseDate': purchaseDate.toIso8601String(),
      };

  factory History.fromMap(Map<String, dynamic> map) => History(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.tryParse('${map['price']}') ?? 0.0,
        quantity: map['quantity'] is int ? map['quantity'] as int : int.tryParse('${map['quantity']}') ?? 0,
        purchaseDate: map['purchaseDate'] != null
            ? DateTime.tryParse(map['purchaseDate'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

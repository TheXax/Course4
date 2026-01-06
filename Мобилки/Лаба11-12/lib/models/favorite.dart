import 'package:hive/hive.dart';

class Favorite extends HiveObject {
  String productId;
  String productName;

  Favorite({required this.productId, required this.productName});

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
      };

  factory Favorite.fromMap(Map<String, dynamic> map) => Favorite(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
      );
}

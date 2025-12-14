import 'package:hive/hive.dart';

class Product extends HiveObject {
  String id;
  String imagePath;
  double price;
  String location;
  int reviewsCount;
  String description;
  bool isLiked;

  Product({
    required this.id,
    required this.imagePath,
    required this.price,
    required this.location,
    required this.reviewsCount,
    required this.description,
    required this.isLiked,
  });
}

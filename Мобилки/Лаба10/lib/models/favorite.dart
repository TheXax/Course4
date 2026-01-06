import 'package:hive/hive.dart';

class Favorite extends HiveObject {
  String productId;
  String productName;

  Favorite({required this.productId, required this.productName});
}

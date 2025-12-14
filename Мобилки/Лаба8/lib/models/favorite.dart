import 'package:hive/hive.dart';

class Favorite extends HiveObject {
  String userId;
  String productId;

  Favorite({required this.userId, required this.productId});
}

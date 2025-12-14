import 'package:hive/hive.dart';

class Cart extends HiveObject { //после того как объект будет сохранён в Hive (через box.put(...)), сам объект получит связь (binding) с боксом и сможет вызывать методы экземпляра для работы с сохранением/удалением
  String userId;
  String productId;
  int quantity;

  Cart({required this.userId, required this.productId, required this.quantity});
}

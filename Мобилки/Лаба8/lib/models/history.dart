import 'package:hive/hive.dart';

class History extends HiveObject {
  String userId;
  String query;
  DateTime date;

  History({required this.userId, required this.query, required this.date});
}

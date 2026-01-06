import 'package:hive/hive.dart';

class User extends HiveObject {
  String id;
  String name;
  String role; // admin, manager, user
  String avatarPath;

  User({required this.id, required this.name, required this.role, required this.avatarPath});
}

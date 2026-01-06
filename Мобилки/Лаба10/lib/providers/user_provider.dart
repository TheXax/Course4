import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';

/// Provider для управления текущим пользователем
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  final List<User> _allUsers = [];

  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;

  UserProvider() {
    _loadUsers();
  }

  /// Загрузить текущего пользователя и список всех пользователей
  void _loadUsers() {
    try {
      final usersBox = Hive.box('users');
      final appBox = Hive.box('app');

      _allUsers.clear();
      for (var key in usersBox.keys) {
        final user = usersBox.get(key) as User;
        _allUsers.add(user);
      }

      // Загрузить текущего пользователя
      final currentUserId = appBox.get('currentUserId') as String?;
      if (currentUserId != null) {
        _currentUser = usersBox.get(currentUserId) as User?;
      } else if (_allUsers.isNotEmpty) {
        _currentUser = _allUsers.first;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  /// Переключиться на другого пользователя
  void switchUser(String userId) {
    try {
      final usersBox = Hive.box('users');
      final appBox = Hive.box('app');

      final user = usersBox.get(userId);
      if (user != null) {
        _currentUser = user as User;
        appBox.put('currentUserId', userId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error switching user: $e');
    }
  }

  /// Получить роль текущего пользователя
  String? get currentUserRole => _currentUser?.role;

  /// Проверить, является ли текущий пользователь администратором
  bool get isAdmin => _currentUser?.role == 'admin';

  /// Проверить, является ли текущий пользователь менеджером
  bool get isManager => _currentUser?.role == 'manager';
}

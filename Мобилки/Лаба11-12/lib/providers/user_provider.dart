import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../services/presence_service.dart';

//Provider для управления текущим пользователем и интеграции с Firebase Auth/Firestore
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  final List<User> _allUsers = [];
  final AuthService _auth = AuthService(); //сервис авторизации
  final FirebaseService _fs = FirebaseService();

  bool _signedIn = false;

  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
  bool get signedIn => _signedIn;

  UserProvider() {
    _loadUsers();

    // Подписка на изменения состояния авторизации Firebase
    //вызывается при входе/выходе/запуске приложения
    _auth.authStateChanges().listen((fb.User? fbUser) async {
      if (fbUser == null) { //пользователь не авторизован
        _signedIn = false;
        // если раньше был пользователь, то помечаем как offline
        if (_currentUser != null) {
          try {
            await PresenceService.instance.setOffline(_currentUser!.id);
          } catch (_) {}
        }
        notifyListeners();
        return;
      }

      _signedIn = true;//пользователь вошёл

      // Попробовать получить профиль пользователя из Firestore
      try {
        final doc = await _fs.getDocument('users', fbUser.uid);
        if (doc.exists) { //профиль есть
          final data = doc.data() as Map<String, dynamic>;
          final u = User(
            id: fbUser.uid,
            name: data['name'] ?? fbUser.displayName ?? fbUser.email ?? 'User',
            role: data['role'] ?? 'user',
            avatarPath: data['avatarPath'] ?? '',
          );

          //сохраняем в Hive
          final usersBox = Hive.box('users');
          usersBox.put(u.id, u);

          _currentUser = u;
          try {
            await PresenceService.instance.setOnline(u.id); //помечаем как online
          } catch (_) {}
          if (!_allUsers.any((x) => x.id == u.id)) _allUsers.add(u);
          final appBox = Hive.box('app');
          appBox.put('currentUserId', u.id);
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error fetching user profile from Firestore: $e');
      }

      // Если профиля нет — создать минимальный профиль и сохранить
      final newUser = User(
        id: fbUser.uid,
        name: fbUser.displayName ?? fbUser.email ?? 'User',
        role: 'user',
        avatarPath: '',
      );
      try { //сохраняем в Firestore
        await _fs.setDocument('users', newUser.id, {
          'name': newUser.name,
          'role': newUser.role,
          'avatarPath': newUser.avatarPath,
          'email': fbUser.email,
        });
      } catch (e) {
        debugPrint('Error creating user in Firestore: $e');
      }

      final usersBox = Hive.box('users');
      usersBox.put(newUser.id, newUser);
      _currentUser = newUser;
      try {
        await PresenceService.instance.setOnline(newUser.id);
      } catch (_) {}
      if (!_allUsers.any((x) => x.id == newUser.id)) _allUsers.add(newUser);
      final appBox = Hive.box('app');
      appBox.put('currentUserId', newUser.id);
      notifyListeners();
    });
  }

  //Загрузить текущего пользователя и список всех пользователей
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

  //Переключиться на другого пользователя (локально)
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

  //Получить роль текущего пользователя
  String? get currentUserRole => _currentUser?.role;

  //Проверить, является ли текущий пользователь администратором
  bool get isAdmin => _currentUser?.role == 'admin';

  //Проверить, является ли текущий пользователь менеджером
  bool get isManager => _currentUser?.role == 'manager';
}

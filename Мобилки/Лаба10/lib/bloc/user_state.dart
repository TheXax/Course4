import '../models/user.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class UserLoadSuccess extends UserState {
  final List<User> allUsers;
  final User? currentUser;

  UserLoadSuccess({required this.allUsers, required this.currentUser});

  bool get isAdmin => currentUser?.role == 'admin';
  bool get isManager => currentUser?.role == 'manager';
}

class UserOperationFailure extends UserState {
  final String message;
  UserOperationFailure(this.message);
}

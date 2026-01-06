import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'user_event.dart';
import 'user_state.dart';
import '../models/user.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<SwitchUser>(_onSwitchUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    try {
      final usersBox = Hive.box('users');
      final appBox = Hive.box('app');
      final List<User> all = [];
      for (var key in usersBox.keys) {
        final u = usersBox.get(key) as User;
        all.add(u);
      }
      User? current;
      final currentUserId = appBox.get('currentUserId') as String?;
      if (currentUserId != null) current = usersBox.get(currentUserId) as User?;
      if (current == null && all.isNotEmpty) current = all.first;
      emit(UserLoadSuccess(allUsers: all, currentUser: current));
    } catch (e) {
      emit(UserOperationFailure('Failed to load users: $e'));
    }
  }

  Future<void> _onSwitchUser(SwitchUser event, Emitter<UserState> emit) async {
    try {
      final usersBox = Hive.box('users');
      final appBox = Hive.box('app');
      final user = usersBox.get(event.userId) as User?;
      if (user != null) {
        appBox.put('currentUserId', event.userId);
        final currentState = state;
        final all = currentState is UserLoadSuccess ? currentState.allUsers : <User>[];
        emit(UserLoadSuccess(allUsers: all, currentUser: user));
      }
    } catch (e) {
      emit(UserOperationFailure('Failed to switch user: $e'));
    }
  }
}

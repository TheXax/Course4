abstract class UserEvent {}

class LoadUsers extends UserEvent {}

class SwitchUser extends UserEvent {
  final String userId;
  SwitchUser(this.userId);
}

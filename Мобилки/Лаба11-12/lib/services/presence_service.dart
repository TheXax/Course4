import 'package:firebase_database/firebase_database.dart';

//в сети ли пользователь и когда был активен последний раз
class PresenceService {
  PresenceService._internal();
  static final PresenceService instance = PresenceService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref(); //создаёт корневой путь к Realtime DB

  //обновление статуса на online
  Future<void> setOnline(String uid) async {
    final ref = _db.child('presence').child(uid);
    try {
      await ref.update({'online': true, 'lastActive': DateTime.now().toIso8601String()});
      //срабатывает, если приложение закрыто по какой-то причине
      await ref.onDisconnect().update({'online': false, 'lastActive': DateTime.now().toIso8601String()});
    } catch (e) {
      // ignore
    }
  }

  Future<void> setOffline(String uid) async {
    final ref = _db.child('presence').child(uid);
    try {
      await ref.update({'online': false, 'lastActive': DateTime.now().toIso8601String()});
    } catch (e) {
      // ignore
    }
  }

  Future<void> updateLastActive(String uid) async {
    final ref = _db.child('presence').child(uid);
    try {
      await ref.update({'lastActive': DateTime.now().toIso8601String()});
    } catch (e) {}
  }
}

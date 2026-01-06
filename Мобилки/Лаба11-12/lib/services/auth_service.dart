import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'analytics_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']); //запрашивает доступ к почте пользователя

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  //регистрация по email
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    try {
      await AnalyticsService.instance.logEvent( //логирует событие регистрации
        'sign_up',
        parameters: {'method': 'email'}, //указываем метод - email
      );
      await AnalyticsService.instance.setUserId(cred.user?.uid); //связь аналитики с пользователем
    } catch (_) {}
    return cred;
  }

  //вход по email
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    try {
      await AnalyticsService.instance.logEvent(
        'sign_in',
        parameters: {'method': 'email'},
      );
      await AnalyticsService.instance.setUserId(cred.user?.uid);
    } catch (_) {}
    return cred;
  }

  //сброс пароля
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email); //отправляем email с ссылкой
    try {
      await AnalyticsService.instance.logEvent('password_reset_requested');
    } catch (_) {}
  }

  //выход из аккаунта
  Future<void> signOut() async {
    try {
      await AnalyticsService.instance.logEvent('sign_out');
    } catch (_) {}
    await _auth.signOut(); //завершаем сессию Firebase
    try {
      await AnalyticsService.instance.setUserId(null);
    } catch (_) {}
  }

  //вход через гугл
  Future<UserCredential?> signInWithGoogle() async {
    // открывает гугл-аккаунты
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication; //получаем токен
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential result;
    try {
      // если пользователь уже пошёл по email, то гугл-аккаунт привязывается, а не создаётся
      if (_auth.currentUser != null) {
        result = await _auth.currentUser!.linkWithCredential(credential);
      } else {
        result = await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      // существует аккаунт с другим методом входа
      if (e.code == 'account-exists-with-different-credential') {
        result = await _auth.signInWithCredential(credential);
      } else {
        rethrow;
      }
    }

    try {
      await AnalyticsService.instance.logEvent(
        'sign_in',
        parameters: {'method': 'google'},
      );
      await AnalyticsService.instance.setUserId(result.user?.uid);
    } catch (_) {}
    return result;
  }
}

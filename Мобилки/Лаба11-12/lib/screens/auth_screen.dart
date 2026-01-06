import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  late TabController _tabController; //переключатель между входом и регистрацией

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { //освобождаем ресурсы, чтобы не было утечки памяти
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email';
    final email = value.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter password';
    if (value.length < 6) return 'Min 6 characters';
    return null;
  }

  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      //вход чере Firebase Auth
      await _auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      _showMessage('Signed in');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Sign in error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  //регистрация
  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await _auth.signUpWithEmail( //создание пользователя
        _emailController.text.trim(),
        _passwordController.text,
      );
      // обновляем имя пользователя в профиле
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        await cred.user?.updateDisplayName(name);
      }
      if (!mounted) return;
      _showMessage('Account created');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Sign up error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  //сброс пароля
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter email to reset password');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email); //Firebase отправляет письмо для сброса пароля
      if (!mounted) return;
      _showMessage('Password reset email sent');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Reset error: $e');
    }
  }

  //вход через гугл
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final cred = await _auth.signInWithGoogle();
      if (cred != null) { //если пользоатель не отменил вход
        if (!mounted) return;
        _showMessage('Signed in as ${cred.user?.email}');
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        _showMessage('Google sign in cancelled');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Google sign in error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Register'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSignIn(), _buildRegister()],
      ),
    );
  }

  Widget _buildSignIn() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _signInFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            ElevatedButton( //кнопка блокируется при загрузке
              onPressed: _loading ? null : _signIn,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Sign In'),
            ),
            TextButton(
              onPressed: _resetPassword,
              child: const Text('Forgot password?'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: _loading ? null : _signInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegister() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _signUp,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

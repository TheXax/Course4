import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  final _nameController = TextEditingController();
  final _photoController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    _nameController.text = user?.displayName ?? '';
    _photoController.text = user?.photoURL ?? '';
    if (user == null) return;
    try {
      final doc = await _firebaseService.getDocument('users', user.uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? _nameController.text;
        _photoController.text = data['avatarPath'] ?? _photoController.text;
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await user.updateDisplayName(_nameController.text.trim());
      if (_photoController.text.trim().isNotEmpty) {
        await user.updatePhotoURL(_photoController.text.trim());
      }
      await _firebaseService.setDocument('users', user.uid, {
        'name': _nameController.text.trim().isEmpty ? user.email : _nameController.text.trim(),
        'avatarPath': _photoController.text.trim(),
        'email': user.email,
        'role': 'user',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update error: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(child: Text('Not signed in'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${user.uid}'),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email ?? '—'}'),
                    const SizedBox(height: 8),
                    Text('Last login: ${user.metadata.lastSignInTime ?? '—'}'),
                    const SizedBox(height: 16),
                    StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('presence/${user.uid}').onValue,
                      builder: (context, snapshot) {
                        final data = snapshot.data?.snapshot.value as Map?;
                        final online = data?['online'] == true;
                        final lastActive = data?['lastActive'] as String?;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${online ? 'Online' : 'Offline'}'),
                            if (lastActive != null) Text('Last active: $lastActive'),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Display name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _photoController,
                      decoration: const InputDecoration(labelText: 'Avatar URL (optional)'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving ? const CircularProgressIndicator() : const Text('Save profile'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _authService.signOut();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

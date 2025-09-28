import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/profile_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _profiles = ProfileRepository();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _login({bool anon = false}) async {
    setState(() { _busy = true; _error = null; });
    try {
      if (anon) {
        final cred = await _auth.signInAnonymously();
        await _profiles.ensureProfile(cred.user!.uid);
      } else {
        final cred = await _auth.signInWithEmailPassword(_email.text.trim(), _password.text.trim());
        await _profiles.ensureProfile(cred.user!.uid, username: _email.text.split('@').first);
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/feed');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ascendia – Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : () => _login(anon: false),
              child: _busy ? const CircularProgressIndicator() : const Text('Login / Register'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _busy ? null : () => _login(anon: true), child: const Text('Continue as Guest')),
          ],
        ),
      ),
    );
  }
}

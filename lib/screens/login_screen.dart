import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    final api = AuthApi();
    final token = await api.login(
      username: _username.text.trim(),
      password: _password.text,
    );

    setState(() => _loading = false);

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Check username/password.')),
      );
      return;
    }

    if (!mounted) return;
    await Provider.of<AppProvider>(context, listen: false).setAccessToken(token);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login successful!')),
    );

    Navigator.pop(context); // go back to home
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(title: const Text('Login'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? 'Logging in...' : 'Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
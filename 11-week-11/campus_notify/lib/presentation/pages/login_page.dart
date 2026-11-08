import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/errors/auth_exception.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: 'emilys@polinema.ac.id');
  final _password = TextEditingController(text: 'emilyspass');
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fillApiCredentials() {
    setState(() {
      _email.text = 'emilys@polinema.ac.id';
      _password.text = 'emilyspass';
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    await ref.read(authStateProvider.notifier).login(
          _email.text.trim(),
          _password.text,
        );

    final state = ref.read(authStateProvider);
    if (!mounted || !state.hasError) return;

    final error = state.error;
    setState(() {
      _error = error is AuthException
          ? error.message
          : 'Login gagal. Silakan coba lagi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Login API')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email / Akun Kampus',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Kata sandi',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _submit,
            icon: const Icon(Icons.login_rounded),
            label: Text(isLoading ? 'Memproses ke API...' : 'Masuk via API'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isLoading ? null : _fillApiCredentials,
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Isi Kredensial API (emilys@polinema.ac.id)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Terhubung ke REST API JWT (POST https://dummyjson.com/auth/login & /auth/refresh). '
            'Akun API default: emilys@polinema.ac.id / emilyspass. '
            'Token disimpan terenkripsi di flutter_secure_storage.',
          ),
        ],
      ),
    );
  }
}

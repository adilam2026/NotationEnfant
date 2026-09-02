import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'email_confirmation_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final ok = await auth.signIn(email: email, password: _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      // LoginScreen is reached by pushing on top of WelcomeScreen — pop back
      // to the root route so AuthGate's now-signed-in state (RootShell)
      // becomes visible instead of staying stuck on this pushed screen.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (auth.lastSignInNeedsConfirmation) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EmailConfirmationScreen(email: email)),
      );
      return;
    }
    if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Connexion')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text('⭐', style: TextStyle(fontSize: 40), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Email invalide'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: auth.isBusy ? null : () => _submit(auth),
                  child: auth.isBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

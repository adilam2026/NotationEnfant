import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'email_confirmation_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _familyNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final outcome = await auth.createFamily(
      familyName: _familyNameCtrl.text.trim(),
      email: email,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    switch (outcome) {
      case SignUpOutcome.signedIn:
        // AuthGate reacts to the new session and swaps screens on its own.
        break;
      case SignUpOutcome.needsConfirmation:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmailConfirmationScreen(email: email),
          ),
        );
        break;
      case SignUpOutcome.failed:
        if (auth.errorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text('👋', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text(
                  'Bienvenue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Créez votre espace famille',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _familyNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la famille',
                    prefixIcon: Icon(Icons.family_restroom_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
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
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Au moins 6 caractères'
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isBusy ? null : () => _submit(auth),
                  child: auth.isBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Créer mon espace'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('J\'ai déjà un compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

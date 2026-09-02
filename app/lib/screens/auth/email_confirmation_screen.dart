import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

/// Shown right after sign-up when the Supabase project requires email
/// confirmation (signUp() returned a user but no session). This is a
/// success state, not an error — the account was created, it just isn't
/// usable yet.
class EmailConfirmationScreen extends StatefulWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  bool _resent = false;

  Future<void> _resend(AuthProvider auth) async {
    final ok = await auth.resendConfirmationEmail(widget.email);
    if (!mounted) return;
    if (ok) {
      setState(() => _resent = true);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📩', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              const Text(
                'Vérifiez votre email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nous avons envoyé un lien de confirmation à :',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ouvrez cet email et touchez le lien pour activer votre espace famille, puis revenez ici et connectez-vous.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),
              if (_resent)
                const Text(
                  '✅ Email renvoyé !',
                  style: TextStyle(
                    color: AppColors.mintDark,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                OutlinedButton(
                  onPressed: auth.isBusy ? null : () => _resend(auth),
                  child: const Text('Renvoyer l\'email'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

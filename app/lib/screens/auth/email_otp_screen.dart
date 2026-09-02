import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/otp_code_field.dart';

enum _Step { email, otp }

/// Single-screen auth flow: email → 6-digit OTP → connected session.
/// No password, no magic link, no separate "create account" screen — the
/// same email field and the same OTP step handle both a brand-new address
/// and an existing account identically (Supabase creates the account
/// transparently on first use).
class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  _Step _step = _Step.email;

  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpFieldKey = GlobalKey<OtpCodeFieldState>();

  String _otpValue = '';
  String? _otpError;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  String get _email => _emailCtrl.text.trim();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(_email);
    if (!mounted) return;
    if (ok) {
      setState(() => _step = _Step.otp);
      _startCooldown();
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(_email);
    if (!mounted) return;
    if (ok) {
      _otpFieldKey.currentState?.clear();
      setState(() {
        _otpValue = '';
        _otpError = null;
      });
      _startCooldown();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Code renvoyé.')));
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  void _onValidatePressed() {
    if (_otpValue.length < OtpCodeField.length) {
      setState(() => _otpError = 'Saisissez les 6 chiffres du code.');
      return;
    }
    _verify(_otpValue);
  }

  Future<void> _verify(String code) async {
    if (code.length != OtpCodeField.length) return;
    setState(() => _otpError = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(email: _email, token: code);
    if (!mounted) return;
    if (!ok) {
      setState(() => _otpError = auth.errorMessage);
      _otpFieldKey.currentState?.clear();
      setState(() => _otpValue = '');
    }
    // On success AuthGate swaps this screen out on its own once the
    // session appears — nothing to navigate to here.
  }

  void _backToEmail() {
    _cooldownTimer?.cancel();
    setState(() {
      _step = _Step.email;
      _otpValue = '';
      _otpError = null;
      _cooldownSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PopScope(
          canPop: _step == _Step.email,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _step == _Step.otp) _backToEmail();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _step == _Step.email
                ? _buildEmailStep(auth)
                : _buildOtpStep(auth),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(AuthProvider auth) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Text('⭐', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'Bienvenue sur Mes Étoiles',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            onFieldSubmitted: (_) => _submitEmail(),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email invalide' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: auth.isBusy ? null : _submitEmail,
            child: auth.isBusy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        IconButton(
          alignment: Alignment.centerLeft,
          onPressed: _backToEmail,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Text('✉️', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const Text(
          'Vérifiez votre email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nous avons envoyé un code à 6 chiffres à\n$_email',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        OtpCodeField(
          key: _otpFieldKey,
          errorText: _otpError,
          onChanged: (v) => setState(() {
            _otpValue = v;
            if (_otpError != null) _otpError = null;
          }),
          onCompleted: _verify,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: auth.isBusy ? null : _onValidatePressed,
          child: auth.isBusy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('Valider'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _cooldownSeconds > 0 || auth.isBusy ? null : _resend,
            child: Text(
              _cooldownSeconds > 0
                  ? 'Renvoyer dans ${_cooldownSeconds}s'
                  : 'Renvoyer le code',
            ),
          ),
        ),
      ],
    );
  }
}

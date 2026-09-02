import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../auth/welcome_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'root_shell.dart';
import 'splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _onboardingSeen;
  String? _initializedForProfile;

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
  }

  Future<void> _loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _onboardingSeen = prefs.getBool('onboarding_seen') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.unknown || _onboardingSeen == null) {
      return const SplashScreen();
    }

    if (auth.status == AuthStatus.signedOut) {
      if (!_onboardingSeen!) {
        return OnboardingScreen(
          onDone: () => setState(() => _onboardingSeen = true),
        );
      }
      return const WelcomeScreen();
    }

    // Signed in.
    if (auth.profile == null) {
      return const SplashScreen();
    }

    final profileId = auth.profile!.id;
    if (_initializedForProfile != profileId) {
      _initializedForProfile = profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FamilyProvider>().init(profileId);
      });
    }

    return const RootShell();
  }
}

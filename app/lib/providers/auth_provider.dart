import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_profile.dart';
import '../services/supabase_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  final _service = SupabaseService.instance;

  AuthStatus status = AuthStatus.unknown;
  FamilyProfile? profile;
  String? errorMessage;
  bool isBusy = false;

  AuthProvider() {
    status = _service.currentUser == null
        ? AuthStatus.signedOut
        : AuthStatus.signedIn;
    if (status == AuthStatus.signedIn) {
      _loadProfile();
    }
    _service.authStateChanges.listen(_onAuthChange);
  }

  void _onAuthChange(AuthState state) {
    final signedIn = state.session != null;
    final newStatus = signedIn ? AuthStatus.signedIn : AuthStatus.signedOut;
    if (newStatus != status) {
      status = newStatus;
      if (signedIn) {
        _loadProfile();
      } else {
        profile = null;
      }
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    try {
      // Creates the `profiles` row on first call for this account if it's
      // missing — the normal case right after the very first OTP
      // verification for a brand-new account.
      await _service.ensureProfileForCurrentUser();
      profile = await _service.fetchProfile();
      notifyListeners();
    } catch (_) {
      // Profile fetch failures surface where the caller can retry; the auth
      // state itself is still valid.
    }
  }

  /// Sends (or resends) the 6-digit email OTP code. Same call for a
  /// brand-new address and an existing account — Supabase auto-creates the
  /// account on first use, so there is only ever one flow to drive here.
  Future<bool> sendOtp(String email) => _run(() => _service.sendOtp(email));

  Future<bool> verifyOtp({required String email, required String token}) {
    return _run(() => _service.verifyOtp(email: email, token: token));
  }

  Future<void> signOut() async {
    await _service.signOut();
    profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() => _loadProfile();

  Future<void> updateFamilyName(String name) async {
    await _service.updateFamilyName(name);
    profile = profile?.copyWith(familyName: name);
    notifyListeners();
  }

  Future<void> updateParentPin(String pin) async {
    await _service.updateParentPin(pin);
    profile = profile?.copyWith(parentPin: pin);
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isBusy = false;
      notifyListeners();
      return true;
    } catch (error) {
      isBusy = false;
      errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }
}

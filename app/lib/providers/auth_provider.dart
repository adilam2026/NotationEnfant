import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_profile.dart';
import '../navigation.dart';
import '../services/supabase_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Outcome of [AuthProvider.createFamily]. `needsConfirmation` is a normal,
/// expected result whenever the Supabase project requires email
/// confirmation (session is null right after signUp) — it is NOT an error.
enum SignUpOutcome { signedIn, needsConfirmation, failed }

class AuthProvider extends ChangeNotifier {
  final _service = SupabaseService.instance;

  AuthStatus status = AuthStatus.unknown;
  FamilyProfile? profile;
  String? errorMessage;
  bool isBusy = false;

  /// Set alongside [errorMessage] when the last failed [signIn] call failed
  /// specifically because the account's email isn't confirmed yet, so the
  /// UI can offer "resend the confirmation email" instead of a dead end.
  bool lastSignInNeedsConfirmation = false;

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
        // Covers returning from the Supabase confirmation-email deep link:
        // the app resumes with LoginScreen/EmailConfirmationScreen still
        // pushed on top of the (now stale) signed-out root route, and
        // nothing local is around to pop it — do it here instead so the
        // now-signed-in RootShell actually becomes visible.
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else {
        profile = null;
      }
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    try {
      // Creates the `profiles` row on first call for this account if it's
      // missing — the normal case right after a fresh email confirmation,
      // since signUpFamily couldn't create it earlier (no session yet).
      await _service.ensureProfileForCurrentUser();
      profile = await _service.fetchProfile();
      notifyListeners();
    } catch (_) {
      // Profile fetch failures surface where the caller can retry; the auth
      // state itself is still valid.
    }
  }

  Future<SignUpOutcome> createFamily({
    required String familyName,
    required String email,
    required String password,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final signedInImmediately = await _service.signUpFamily(
        email: email,
        password: password,
        familyName: familyName,
      );
      if (signedInImmediately) {
        await _loadProfile();
      }
      isBusy = false;
      notifyListeners();
      return signedInImmediately
          ? SignUpOutcome.signedIn
          : SignUpOutcome.needsConfirmation;
    } catch (error) {
      isBusy = false;
      errorMessage = error.toString();
      notifyListeners();
      return SignUpOutcome.failed;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    lastSignInNeedsConfirmation = false;
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.signIn(email: email, password: password);
      isBusy = false;
      notifyListeners();
      return true;
    } catch (error) {
      isBusy = false;
      errorMessage = error.toString();
      lastSignInNeedsConfirmation = isEmailNotConfirmedError(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendConfirmationEmail(String email) {
    return _run(() => _service.resendConfirmationEmail(email));
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _service.sendPasswordReset(email));
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

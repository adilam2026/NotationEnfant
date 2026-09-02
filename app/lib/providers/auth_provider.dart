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
      profile = await _service.fetchProfile();
      notifyListeners();
    } catch (_) {
      // Profile fetch failures surface where the caller can retry; the auth
      // state itself is still valid.
    }
  }

  Future<bool> createFamily({
    required String familyName,
    required String email,
    required String password,
  }) async {
    return _run(() async {
      await _service.signUpFamily(
        email: email,
        password: password,
        familyName: familyName,
      );
      await _loadProfile();
    });
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _service.signIn(email: email, password: password));
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

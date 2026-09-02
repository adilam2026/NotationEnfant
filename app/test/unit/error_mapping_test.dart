import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mes_etoiles/services/error_mapping.dart';
import 'package:mes_etoiles/utils/auth_redirect.dart';

void main() {
  group('mapSupabaseError — AuthException with a typed code', () {
    test('email_not_confirmed maps to a friendly message with the matching code', () {
      final result = mapSupabaseError(
        const AuthException('Email not confirmed', code: 'email_not_confirmed'),
      );
      expect(result.code, 'email_not_confirmed');
      expect(result.message, contains('Confirmez votre email'));
      expect(isEmailNotConfirmedError(result), isTrue);
    });

    test('invalid_credentials maps to a wrong-password message, not confirmation', () {
      final result = mapSupabaseError(
        const AuthException('Invalid login credentials', code: 'invalid_credentials'),
      );
      expect(result.message, 'Email ou mot de passe incorrect.');
      expect(isEmailNotConfirmedError(result), isFalse);
    });

    test('user_already_exists maps to an already-registered message', () {
      final result = mapSupabaseError(
        const AuthException('User already registered', code: 'user_already_exists'),
      );
      expect(result.message, contains('existe déjà'));
    });

    test('weak_password maps to a length-requirement message', () {
      final result = mapSupabaseError(
        const AuthException('Password too short', code: 'weak_password'),
      );
      expect(result.message, contains('6 caractères'));
    });
  });

  group('mapSupabaseError — AuthException without a code (older/self-hosted)', () {
    test('falls back to matching "email not confirmed" in the raw message', () {
      final result = mapSupabaseError(
        const AuthException('Email not confirmed'),
      );
      expect(isEmailNotConfirmedError(result), isTrue);
    });

    test('never leaks the raw technical message to the user', () {
      final result = mapSupabaseError(
        const AuthException('some unexpected gotrue internal detail'),
      );
      expect(result.message, isNot(contains('gotrue')));
    });
  });

  group('mapSupabaseError — PostgrestException (RPC business errors)', () {
    test('insufficient_stars maps to a friendly reward message', () {
      final result = mapSupabaseError(
        PostgrestException(message: 'insufficient_stars'),
      );
      expect(result.message, contains('assez d\'étoiles'));
    });

    test('an RLS/unexpected Postgrest error never leaks the raw message', () {
      final result = mapSupabaseError(
        PostgrestException(message: 'new row violates row-level security policy'),
      );
      expect(result.message, 'Impossible de synchroniser pour le moment.');
    });
  });

  test('a non-Supabase error still produces a safe generic message', () {
    final result = mapSupabaseError(Exception('boom'));
    expect(result.message, isNotEmpty);
  });

  test('isEmailNotConfirmedError is false for an unrelated AppException', () {
    expect(isEmailNotConfirmedError(AppException('Une erreur est survenue.')), isFalse);
  });

  test('the confirmation/reset deep link never points at localhost', () {
    expect(kAuthRedirectUrl.contains('localhost'), isFalse);
    expect(kAuthRedirectUrl.contains('127.0.0.1'), isFalse);
    expect(kAuthRedirectUrl, startsWith('io.mesetoiles.app://'));
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mes_etoiles/services/error_mapping.dart';

void main() {
  group('mapSupabaseError — AuthRetryableFetchException (network failure)', () {
    test('maps to the French "no internet" message, not the generic fallback', () {
      // Confirmed by reading gotrue's fetch.dart: ANY failure reaching the
      // underlying http client (DNS, connection refused, TLS, timeout —
      // whatever the concrete Dart exception type) is caught and rethrown
      // as this specific AuthException subclass, before any HTTP response
      // exists. It must not fall through to the generic "Une erreur est
      // survenue" — that was a real bug caught via a live device test.
      final result = mapSupabaseError(
        AuthRetryableFetchException(message: 'ClientException: Failed host lookup'),
      );
      expect(result.message, 'Connexion impossible. Vérifiez votre connexion internet.');
    });
  });

  group('mapSupabaseError — AuthException with a typed code', () {
    test('otp_expired maps to a single honest "incorrect ou expiré" message', () {
      // The Supabase server itself doesn't distinguish a wrong code from an
      // expired one — both come back as this exact code. Splitting it into
      // two different messages client-side would be guessing, not fact.
      final result = mapSupabaseError(
        const AuthException('Token has expired or is invalid', code: 'otp_expired'),
      );
      expect(result.message, contains('incorrect'));
      expect(result.message, contains('expiré'));
    });

    test('over_email_send_rate_limit maps to a rate-limit message', () {
      final result = mapSupabaseError(
        const AuthException('Rate limit exceeded', code: 'over_email_send_rate_limit'),
      );
      expect(result.message, 'Trop de tentatives. Attendez quelques instants avant de réessayer.');
    });

    test('validation_failed (malformed email) maps to a clear message', () {
      final result = mapSupabaseError(
        const AuthException('Unable to validate email address', code: 'validation_failed'),
      );
      expect(result.message, contains('email invalide'));
    });
  });

  group('mapSupabaseError — AuthException without a typed code', () {
    test('falls back to matching "token has expired" in the raw message', () {
      final result = mapSupabaseError(
        const AuthException('Token has expired or is invalid'),
      );
      expect(result.message, contains('incorrect'));
    });

    test('never leaks a raw technical message to the user', () {
      final result = mapSupabaseError(
        const AuthException('some unexpected gotrue internal detail'),
      );
      expect(result.message, isNot(contains('gotrue')));
      expect(result.message, 'Une erreur est survenue. Réessayez.');
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

  group('mapSupabaseError — connectivity', () {
    test('a SocketException maps to a French "no internet" message', () {
      final result = mapSupabaseError(const SocketException('Failed host lookup'));
      expect(result.message, 'Connexion impossible. Vérifiez votre connexion internet.');
    });

    test('a TimeoutException maps to the same "no internet" message', () {
      final result = mapSupabaseError(TimeoutException('timed out'));
      expect(result.message, 'Connexion impossible. Vérifiez votre connexion internet.');
    });
  });

  test('an unrecognized error still produces a safe generic message', () {
    final result = mapSupabaseError(Exception('boom'));
    expect(result.message, isNotEmpty);
    expect(result.message, isNot(contains('boom')));
  });

  test('no AppException message ever contains raw exception type names', () {
    const rawTypeNames = ['AuthException', 'PostgrestException', 'StackTrace'];
    final samples = [
      mapSupabaseError(const AuthException('x', code: 'otp_expired')),
      mapSupabaseError(PostgrestException(message: 'insufficient_stars')),
      mapSupabaseError(Exception('boom')),
    ];
    for (final sample in samples) {
      for (final typeName in rawTypeNames) {
        expect(sample.message, isNot(contains(typeName)));
      }
    }
  });
}

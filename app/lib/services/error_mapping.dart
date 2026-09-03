import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing exception. Never expose a raw Supabase/Postgrest error
/// message to a parent — always go through [mapSupabaseError] first.
class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});
  @override
  String toString() => message;
}

/// Translates a raw Supabase/Postgrest/network error into a short, friendly
/// French message. Pure function (no Supabase client access) so it can be
/// unit tested directly — see test/unit/error_mapping_test.dart.
AppException mapSupabaseError(Object error) {
  if (error is AuthRetryableFetchException) {
    // Thrown by gotrue for any network/CORS-level failure reaching Supabase
    // at all (verified in gotrue's fetch.dart: any exception from the
    // underlying http client, whatever its concrete type, is caught and
    // rethrown as this one) — distinct from a request that reached the
    // server and got an error response back.
    return AppException('Connexion impossible. Vérifiez votre connexion internet.');
  }

  if (error is AuthException) {
    switch (error.code) {
      case 'otp_expired':
        // Supabase's GoTrue server does not distinguish "wrong code" from
        // "expired code" — both come back as this same error code with the
        // message "Token has expired or is invalid." (verified in the
        // gotrue package source: there is no separate "invalid" code). A
        // single message that covers both is more honest than guessing.
        return AppException(
          'Code incorrect ou expiré. Vérifiez le code reçu, ou demandez-en un nouveau.',
        );
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
      case 'over_sms_send_rate_limit':
        return AppException('Trop de tentatives. Attendez quelques instants avant de réessayer.');
      case 'validation_failed':
        return AppException('Adresse email invalide.');
    }

    // Older/self-hosted Supabase instances don't always send a typed
    // `code` — fall back to matching the message in that case.
    final msg = error.message.toLowerCase();
    if (msg.contains('token has expired') || msg.contains('otp_expired')) {
      return AppException(
        'Code incorrect ou expiré. Vérifiez le code reçu, ou demandez-en un nouveau.',
      );
    }
    if (msg.contains('rate limit')) {
      return AppException('Trop de tentatives. Attendez quelques instants avant de réessayer.');
    }
    return AppException('Une erreur est survenue. Réessayez.');
  }

  if (error is PostgrestException) {
    switch (error.message) {
      case 'insufficient_stars':
        return AppException('Pas encore assez d\'étoiles pour cette récompense.');
      case 'reward_not_found':
        return AppException('Cette récompense n\'est plus disponible.');
      case 'not_authorized':
        return AppException('Action non autorisée.');
    }
    return AppException('Impossible de synchroniser pour le moment.');
  }

  if (error is SocketException || error is HttpException || error is TimeoutException) {
    return AppException('Connexion impossible. Vérifiez votre connexion internet.');
  }

  return AppException('Une erreur est survenue. Réessayez.');
}

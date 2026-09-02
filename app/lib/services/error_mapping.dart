import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing exception. Never expose a raw Supabase/Postgrest error
/// message to a parent — always go through [mapSupabaseError] first.
///
/// [code] carries a normalized, stable identifier (e.g.
/// `'email_not_confirmed'`) so UI code can branch on *what* went wrong
/// without re-parsing the (translated, user-facing) [message] — see
/// [isEmailNotConfirmedError].
class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});
  @override
  String toString() => message;
}

const _emailNotConfirmedCode = 'email_not_confirmed';

/// Translates a raw Supabase/Postgrest error into a short, friendly French
/// message. Pure function (no Supabase client access) so it can be unit
/// tested directly — see test/unit/error_mapping_test.dart.
AppException mapSupabaseError(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return AppException('Email ou mot de passe incorrect.');
      case 'user_already_exists':
      case 'email_exists':
        return AppException('Un compte existe déjà avec cet email.');
      case 'email_not_confirmed':
        return AppException(
          'Confirmez votre email avant de vous connecter (vérifiez votre boîte de réception).',
          code: _emailNotConfirmedCode,
        );
      case 'weak_password':
        return AppException('Le mot de passe doit contenir au moins 6 caractères.');
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return AppException('Trop de tentatives, réessayez dans quelques minutes.');
    }

    // Older/self-hosted Supabase instances don't always send a typed
    // `code` — fall back to matching the message in that case.
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return AppException('Email ou mot de passe incorrect.');
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return AppException('Un compte existe déjà avec cet email.');
    }
    if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
      return AppException(
        'Confirmez votre email avant de vous connecter (vérifiez votre boîte de réception).',
        code: _emailNotConfirmedCode,
      );
    }
    if (msg.contains('password') && msg.contains('least')) {
      return AppException('Le mot de passe doit contenir au moins 6 caractères.');
    }
    return AppException('Impossible de vous connecter pour le moment.');
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

  return AppException('Une erreur est survenue. Réessayez.');
}

/// True when [error] is specifically "this account exists but its email
/// hasn't been confirmed yet" — callers use this to offer a resend action
/// instead of a dead-end error. Takes the exception already mapped by
/// [mapSupabaseError] (that's what callers actually catch).
bool isEmailNotConfirmedError(Object error) {
  return error is AppException && error.code == _emailNotConfirmedCode;
}

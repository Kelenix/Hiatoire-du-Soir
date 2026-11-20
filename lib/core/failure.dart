import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreurs que l'app sait expliquer (architecture §6). Les codes viennent des Edge Functions et des
/// fonctions SQL.
enum Failure implements Exception {
  offline,
  timeout,
  quotaReached,
  locked,
  contentRejected,
  favoritesLimit,
  abuseLimit,
  charactersLimit,
  invalidCode,
  unexpected;

  static Failure fromCode(Object? code) => switch (code) {
    'QUOTA_REACHED' => quotaReached,
    'LOCKED' => locked,
    'CONTENT_REJECTED' => contentRejected,
    'FAVORITES_LIMIT' => favoritesLimit,
    'ABUSE_LIMIT' => abuseLimit,
    'CHARACTERS_LIMIT' => charactersLimit,
    'otp_expired' || 'validation_failed' => invalidCode,
    _ => unexpected,
  };

  /// Ce qui doit être demandé à un parent plutôt que réessayé.
  bool get needsParent => this == quotaReached || this == locked;
}

/// Traduit les exceptions de Supabase et du réseau en [Failure]. Les `Error` (bugs) ne sont pas masquées.
Future<T> guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on Failure {
    rethrow; // déjà traduite (appel imbriqué)
  } on FunctionException catch (error) {
    final details = error.details;
    throw Failure.fromCode(details is Map ? details['error'] : null);
  } on AuthException catch (error) {
    // Sans code HTTP, la requête n'a pas atteint le serveur.
    throw error.statusCode == null ? Failure.offline : Failure.fromCode(error.code);
  } on TimeoutException {
    throw Failure.timeout;
  } on PostgrestException catch (error) {
    throw Failure.fromCode(error.message);
  } on Exception {
    throw Failure.offline;
  }
}

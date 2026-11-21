import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config.dart';
import '../../../core/failure.dart';

/// Compte Google du parent, par la fenêtre de choix de compte du téléphone (ADR-038). Seul le jeton
/// d'identité sert : Supabase le vérifie et en tire l'e-mail ; l'app n'accède à aucune donnée Google.
class GoogleIdentity {
  Future<void>? _initialization;

  /// Android seulement : sur iPhone, Apple exige « Se connecter avec Apple » à côté (règle 4.8).
  bool get isAvailable => Platform.isAndroid && AppConfig.googleWebClientId.isNotEmpty;

  /// Jeton d'identité Google, ou null si le parent ferme la fenêtre de choix du compte.
  Future<String?> idToken() async {
    final google = GoogleSignIn.instance;
    await (_initialization ??= google.initialize(serverClientId: AppConfig.googleWebClientId));
    try {
      return (await google.authenticate()).authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw Failure.unexpected; // compte Google ou configuration refusés : rien à réessayer tout de suite
    }
  }

  /// Après une déconnexion, le parent choisit de nouveau son compte.
  Future<void> signOut() async {
    if (_initialization != null) await GoogleSignIn.instance.signOut();
  }
}

final googleIdentityProvider = Provider((ref) => GoogleIdentity());

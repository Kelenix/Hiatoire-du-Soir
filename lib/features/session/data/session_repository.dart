import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failure.dart';
import 'google_identity.dart';

/// Comment le code reçu par e-mail sera vérifié : rattacher l'e-mail à la session anonyme, ou se
/// connecter à un compte existant (2ᵉ appareil).
enum EmailCodePurpose { linkThisDevice, signInExistingAccount }

class SessionRepository {
  const SessionRepository(this._client, this._google);

  final SupabaseClient _client;
  final GoogleIdentity _google;

  GoTrueClient get _auth => _client.auth;

  /// Premier lancement : session anonyme, sans formulaire (US-01). Ensuite, la session rangée
  /// dans le stockage sécurisé est réutilisée telle quelle.
  Future<void> ensureSession() async {
    if (_auth.currentSession != null) return;
    await _auth.signInAnonymously();
  }

  /// Envoie un code à 6 chiffres. La session anonyme devient le compte (mêmes données, ADR-010) ;
  /// si l'e-mail a déjà un compte, on s'y connecte à la place.
  Future<EmailCodePurpose> sendEmailCode(String email) => guard(() async {
    try {
      await _auth.updateUser(UserAttributes(email: email));
      return EmailCodePurpose.linkThisDevice;
    } on AuthException catch (error) {
      if (error.code != 'email_exists') rethrow;
      await _auth.signInWithOtp(email: email, shouldCreateUser: false);
      return EmailCodePurpose.signInExistingAccount;
    }
  });

  Future<void> verifyEmailCode(String email, String code, EmailCodePurpose purpose) => guard(
    () => _auth.verifyOTP(
      email: email,
      token: code,
      type: purpose == EmailCodePurpose.linkThisDevice ? OtpType.emailChange : OtpType.email,
    ),
  );

  /// Connexion Google (US-20, ADR-038) : le compte Google est rattaché à la session anonyme (mêmes
  /// données, ADR-010) ; s'il appartient déjà à une famille (2ᵉ appareil), on s'y connecte à la place.
  /// Renvoie `false` si le parent a fermé la fenêtre de Google.
  Future<bool> signInWithGoogle() => guard(() async {
    final idToken = await _google.idToken();
    if (idToken == null) return false;
    try {
      await _auth.linkIdentityWithIdToken(provider: OAuthProvider.google, idToken: idToken);
    } on AuthException catch (error) {
      if (error.code != 'identity_already_exists') rethrow;
      await _auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
    }
    return true;
  });

  /// Déconnexion ; la porte de session ouvre ensuite une nouvelle session anonyme (sessionProvider).
  Future<void> signOut() => guard(() async {
    await _auth.signOut(scope: SignOutScope.local);
    await _google.signOut();
  });

  /// Suppression définitive du compte et de ses données (US-21), par le serveur.
  Future<void> deleteAccount() => guard(() async {
    await _client.functions.invoke('delete-account');
    await signOut();
  });
}

final sessionRepositoryProvider = Provider(
  (ref) => SessionRepository(Supabase.instance.client, ref.watch(googleIdentityProvider)),
);

/// Utilisateur courant, mis à jour à chaque connexion ou déconnexion.
final authUserProvider = StreamProvider<User?>((ref) async* {
  final auth = Supabase.instance.client.auth;
  yield auth.currentUser;
  yield* auth.onAuthStateChange.map((state) => state.session?.user);
});

/// Compte courant. Les données affichées (droits, histoires, personnages) en dépendent : elles se
/// rechargent d'elles-mêmes à la connexion, à la déconnexion et quand l'e-mail est rattaché.
final accountProvider = Provider<({String? id, bool isAnonymous})>((ref) {
  final user = ref.watch(authUserProvider).valueOrNull;
  return (id: user?.id, isAnonymous: user?.isAnonymous ?? true);
});

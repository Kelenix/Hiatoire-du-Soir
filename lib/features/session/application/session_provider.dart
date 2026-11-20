import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_repository.dart';

/// Session prête : condition préalable à tout écran de l'app. Sans utilisateur (premier lancement,
/// déconnexion, suppression du compte), une nouvelle session anonyme est ouverte ; hors connexion,
/// la porte de session propose de réessayer.
final sessionProvider = FutureProvider<void>((ref) async {
  if (ref.watch(authUserProvider.select((user) => user.valueOrNull != null))) return;
  await ref.read(sessionRepositoryProvider).ensureSession();
});

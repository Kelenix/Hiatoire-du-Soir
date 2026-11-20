import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../parental_gate/application/parental_gate.dart';

/// Ouvre un lien hors de l'app (e-mail, page web), toujours après le contrôle parental (US-16) :
/// déverrouillage encore valide, sinon nouveau défi puis retour à l'Espace Parents.
Future<void> openExternal(BuildContext context, WidgetRef ref, Uri uri) async {
  if (!ref.read(parentalGateProvider.notifier).isUnlocked) {
    await context.push('/controle-parental?suite=/parents');
    return;
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible d’ouvrir ${uri.path}.')));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import 'external_link.dart';

/// Aide et support (US-19, maquette P7).
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  static const _faq = [
    (
      'Combien d’histoires gratuites ?',
      '3 histoires de 2 minutes par semaine, sur les thèmes Animaux et Forêt magique. '
          'Le compteur repart à zéro chaque lundi.',
    ),
    (
      'Pourquoi l’écoute est-elle verrouillée ?',
      'Dans l’offre gratuite, chaque histoire s’écoute une fois. Le texte reste lisible.',
    ),
    (
      'Je n’entends aucune voix.',
      'Vérifiez le volume, puis qu’une voix française est installée : réglages du téléphone, '
          'Accessibilité, Synthèse vocale.',
    ),
    (
      'Les histoires conviennent-elles aux enfants ?',
      'Chaque histoire est relue automatiquement avant d’être affichée. Si l’une d’elles vous paraît '
          'inadaptée, signalez-la depuis l’écran de lecture : elle est retirée aussitôt.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return NightScaffold(
      title: 'Aide et support',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (question, answer) in _faq) ...[
            Text(question, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(answer, style: textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
          ],
          if (AppConfig.supportEmail.isNotEmpty)
            OutlinePillButton(
              label: 'Écrire au support',
              icon: Icons.mail_outline_rounded,
              onPressed: () => openExternal(context, ref, Uri(scheme: 'mailto', path: AppConfig.supportEmail)),
            ),
        ],
      ),
    );
  }
}

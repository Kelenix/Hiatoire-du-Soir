import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/voice.dart';
import '../../offers/data/offers_repository.dart';
import '../../parents/application/reading_settings.dart';
import '../application/listening_controller.dart';

/// Choix de la voix (US-36, maquettes E5 et P6) : celle du téléphone, puis les voix apaisantes, ouvertes
/// au Premium et au Pack Voix. Le choix est gardé dans les réglages de lecture.
class VoiceOptions extends ConsumerWidget {
  const VoiceOptions({super.key, this.onSample, this.onChosen});

  /// Écoute d'un extrait (Espace Parents) ; absente pendant une histoire, dont le lecteur est occupé.
  final void Function(Voice voice)? onSample;
  final VoidCallback? onChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUse = ref.watch(entitlementsProvider).valueOrNull?.canUsePremiumVoices ?? false;
    final voices = ref.watch(voicesProvider).valueOrNull ?? const <Voice>[];
    final selectedId = ref.watch(premiumVoiceProvider)?.id;

    void choose(String? voiceId) {
      ref.read(readingSettingsProvider.notifier).setVoice(voiceId);
      onChosen?.call();
    }

    Widget option({required String title, required String subtitle, String? voiceId, Voice? voice}) {
      final isLocked = voiceId != null && !canUse;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: !isLocked,
        selected: voiceId == selectedId,
        selectedColor: AppColors.gold,
        leading: Icon(
          isLocked
              ? Icons.lock_rounded
              : voiceId == selectedId
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          semanticLabel: isLocked ? 'verrouillée' : null,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: voice != null && onSample != null
            ? IconButton(
                tooltip: 'Écouter un extrait de la voix ${voice.name}',
                icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.gold),
                onPressed: () => onSample!(voice),
              )
            : null,
        onTap: () => choose(voiceId),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        option(title: 'Voix du téléphone', subtitle: 'La voix installée sur ce téléphone.'),
        for (final voice in voices)
          option(title: voice.name, subtitle: voice.description, voiceId: voice.id, voice: voice),
      ],
    );
  }
}

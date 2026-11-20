import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../catalog/domain/voice.dart';
import '../../offers/data/offers_repository.dart';
import '../../player/application/listening_controller.dart';
import '../../player/data/listening_repository.dart';
import '../../player/presentation/voice_options.dart';
import '../application/reading_settings.dart';

/// Réglages de lecture (US-18, US-36, maquette P6), appliqués immédiatement.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Extrait lu par le lecteur unique de l'app (ADR-013) ; écoutable avant tout achat.
  Future<void> _playSample(BuildContext context, WidgetRef ref, Voice voice) async {
    final messenger = ScaffoldMessenger.of(context);
    final player = ref.read(audioPlayerProvider);
    try {
      final url = await ref.read(listeningRepositoryProvider).premiumAudio(voice.id);
      await player.setAudioSource(
        AudioSource.uri(
          url,
          tag: MediaItem(id: 'extrait-${voice.id}', title: 'Extrait : ${voice.name}', album: 'Histoires du Soir'),
        ),
      );
      unawaited(player.play());
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Extrait indisponible pour le moment. Réessayez dans un instant.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(audioPlayerProvider); // lecteur des extraits, arrêté en quittant l'écran
    final settings = ref.watch(readingSettingsProvider).valueOrNull ?? defaultReadingSettings;
    final controller = ref.read(readingSettingsProvider.notifier);
    final canUsePremiumVoices = ref.watch(entitlementsProvider).valueOrNull?.canUsePremiumVoices ?? false;
    final textTheme = Theme.of(context).textTheme;
    return NightScaffold(
      title: 'Réglages de lecture',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Voix de lecture', style: textTheme.titleMedium),
          VoiceOptions(onSample: (voice) => _playSample(context, ref, voice)),
          if (!canUsePremiumVoices) ...[
            Text('Les voix apaisantes sont comprises dans Premium et dans le Pack Voix.', style: textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinePillButton(label: 'Débloquer les voix', onPressed: () => context.push('/parents/packs')),
          ],
          const SizedBox(height: 32),
          Text('Vitesse de la voix', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Lente')),
              ButtonSegment(value: false, label: Text('Normale')),
            ],
            selected: {settings.isSlowVoice},
            onSelectionChanged: (choice) => controller.setSlowVoice(choice.single),
          ),
          const SizedBox(height: 32),
          Text('Taille du texte', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<TextSize>(
            segments: const [
              ButtonSegment(value: TextSize.small, label: Text('Petit')),
              ButtonSegment(value: TextSize.medium, label: Text('Moyen')),
              ButtonSegment(value: TextSize.large, label: Text('Grand')),
            ],
            selected: {settings.textSize},
            onSelectionChanged: (choice) => controller.setTextSize(choice.single),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Il était une fois un petit renard qui regardait les étoiles.',
                style: storyTextStyle.copyWith(fontSize: settings.textSize.points),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

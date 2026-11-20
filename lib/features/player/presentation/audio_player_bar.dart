import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../offers/data/offers_repository.dart';
import '../../stories/domain/story.dart';
import '../application/listening_controller.dart';
import 'voice_options.dart';

/// Lecteur de l'écran de lecture (design system : `AudioPlayerBar`).
class AudioPlayerBar extends ConsumerWidget {
  const AudioPlayerBar({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(listeningProvider(story));
    final controller = ref.read(listeningProvider(story).notifier);
    final canChooseVoice = ref.watch(entitlementsProvider).valueOrNull?.canUsePremiumVoices ?? false;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _PlayButton(status: status, onPressed: controller.toggle),
                const SizedBox(width: 16),
                Expanded(
                  child: switch (status) {
                    ListeningStatus.playing || ListeningStatus.paused => const _Progress(),
                    _ => _StatusMessage(status: status),
                  },
                ),
              ],
            ),
            // L'enfant ne voit le choix que si la famille a des voix apaisantes : ni cadenas ni prix ici.
            if (canChooseVoice)
              _VoiceChoice(
                isEnabled: const [
                  ListeningStatus.ready,
                  ListeningStatus.offline,
                  ListeningStatus.failed,
                ].contains(status),
              ),
          ],
        ),
      ),
    );
  }
}

/// Voix de l'écoute (maquette E5), modifiable avant la lecture.
class _VoiceChoice extends ConsumerWidget {
  const _VoiceChoice({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(premiumVoiceProvider);
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: isEnabled
            ? () => showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: VoiceOptions(onChosen: () => Navigator.pop(sheetContext)),
                  ),
                ),
              )
            : null,
        icon: const Icon(Icons.record_voice_over_rounded),
        label: Text(voice == null ? 'Voix du téléphone' : 'Voix : ${voice.name}'),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.status, required this.onPressed});

  final ListeningStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (label, child) = switch (status) {
      ListeningStatus.playing => ('Mettre en pause', const Icon(Icons.pause_rounded, color: AppColors.gold, size: 40)),
      ListeningStatus.preparing => (
        'Préparation de l’écoute',
        const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
      ),
      ListeningStatus.locked || ListeningStatus.noVoice => (
        'Écoute indisponible',
        const Icon(Icons.lock_rounded, color: AppColors.gold, size: 30),
      ),
      _ => ('Écouter l’histoire', Image.asset(AppImages.iconPlay, width: 44, excludeFromSemantics: true)),
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.lavender, width: 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(dimension: 64, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.status});

  final ListeningStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (status == ListeningStatus.locked) {
      return InkWell(
        onTap: () => context.push('/demande-parent'),
        child: Text('Histoire déjà écoutée.\nDemande à un parent pour la réécouter.', style: textTheme.bodySmall),
      );
    }
    final message = switch (status) {
      ListeningStatus.preparing => 'Le renard s’éclaircit la voix…',
      ListeningStatus.noVoice =>
        'Aucune voix française sur ce téléphone. Un parent peut en installer une dans les réglages : '
            'Accessibilité, puis Synthèse vocale.',
      ListeningStatus.offline => 'Pas de connexion. Touche le bouton pour réessayer.',
      ListeningStatus.failed => 'L’écoute n’a pas démarré. Touche le bouton pour réessayer.',
      _ => 'Écouter l’histoire',
    };
    return Text(message, style: status == ListeningStatus.ready ? textTheme.titleMedium : textTheme.bodySmall);
  }
}

/// Progression de la lecture, en dégradé Magie.
class _Progress extends ConsumerWidget {
  const _Progress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;
        final progress = duration == Duration.zero ? .0 : position.inMilliseconds / duration.inMilliseconds;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.cardBorder),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0, 1),
                      child: const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.magic)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_format(position)} / ${_format(duration)}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  static String _format(Duration duration) =>
      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}

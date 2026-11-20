import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../parents/application/reading_settings.dart';
import '../../player/presentation/audio_player_bar.dart';
import '../application/story_providers.dart';
import '../domain/story.dart';
import 'favorite_button.dart';

/// Lecture, écoute et favori d'une histoire (US-08, US-10, US-13, maquette E5).
class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(storyProvider(storyId));
    return NightScaffold(
      hasStars: false,
      actions: [
        if (story.valueOrNull case final loaded?) ...[
          IconButton(
            tooltip: 'Signaler cette histoire (parents)',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => context.push('/parents/signaler/${loaded.id}'),
          ),
          FavoriteButton(story: loaded),
        ],
      ],
      body: story.when(
        data: (story) => Column(
          children: [
            Expanded(child: _StoryText(story: story)),
            AudioPlayerBar(story: story),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => MascotState(
          title: 'L’histoire se cache…',
          message: 'Vérifie la connexion Internet, puis réessaie.',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(storyProvider(storyId)),
        ),
      ),
    );
  }
}

class _StoryText extends ConsumerWidget {
  const _StoryText({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = (ref.watch(readingSettingsProvider).valueOrNull ?? defaultReadingSettings).textSize;
    final paragraphStyle = storyTextStyle.copyWith(fontSize: textSize.points);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Semantics(
          header: true,
          child: Text(story.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 24),
        for (final paragraph in story.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(paragraph, style: paragraphStyle),
          ),
      ],
    );
  }
}

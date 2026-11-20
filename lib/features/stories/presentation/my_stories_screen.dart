import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../catalog/data/catalog_repository.dart';
import '../application/favorites_providers.dart';
import '../domain/story.dart';

/// « Mes histoires » : les histoires gardées d'un cœur (US-15, maquette E6).
class MyStoriesScreen extends ConsumerWidget {
  const MyStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NightScaffold(
      title: 'Mes histoires',
      body: ref
          .watch(favoritesProvider)
          .when(
            data: (favorites) => favorites.stories.isEmpty
                ? const MascotState(
                    title: 'Aucune histoire gardée',
                    message: 'Touche le cœur d’une histoire pour la retrouver ici.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: favorites.stories.length + (favorites.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => index < favorites.stories.length
                        ? _StoryTile(story: favorites.stories[index])
                        : TextButton(
                            onPressed: ref.read(favoritesProvider.notifier).loadMore,
                            child: const Text('Voir plus'),
                          ),
                  ),
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, _) => const SizedBox(
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
            ),
            error: (_, _) => MascotState(
              title: 'Tes histoires se cachent…',
              message: 'Vérifie la connexion Internet, puis réessaie.',
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(favoritesProvider),
            ),
          ),
    );
  }
}

class _StoryTile extends ConsumerWidget {
  const _StoryTile({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themesProvider).valueOrNull?.where((theme) => theme.id == story.themeId).firstOrNull;
    final image = AppImages.illustration(theme?.illustration ?? '');
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.push('/histoire/${story.id}'),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 80,
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.tile),
                child: Image.asset(
                  image,
                  fit: image == AppImages.mascot ? BoxFit.contain : BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                story.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.favorite_rounded, color: AppColors.heart),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/stars_left.dart';
import '../application/story_providers.dart';
import '../domain/story.dart';

/// Accueil de l'Espace Enfant (US-02, maquette E1 de `docs/design/flows.md`).
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      hasAppBar: false,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: _HomeContent(mascotHeight: constraints.maxHeight * .22)),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.mascotHeight});

  final double mascotHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    final freeStoriesLeft = (entitlements?.isPremium ?? true) ? null : entitlements!.freeStoriesLeft;
    final latestStory = ref.watch(latestStoryProvider).valueOrNull;
    void openThemes() => context.push('/themes');
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: IconTile(
              image: AppImages.iconFamily,
              label: 'Parents',
              size: 56,
              onTap: () => context.push('/parents'),
            ),
          ),
        ),
        const Spacer(),
        Image.asset(AppImages.mascot, height: mascotHeight.clamp(120, 220), excludeFromSemantics: true),
        const SizedBox(height: 12),
        const BrandLogo(),
        const SizedBox(height: 32),
        Text(
          'DES HISTOIRES MAGIQUES\nPOUR DE BEAUX RÊVES',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        if (freeStoriesLeft != null) ...[const SizedBox(height: 16), StarsLeft(count: freeStoriesLeft)],
        const Spacer(),
        MagicButton(label: 'Créer une histoire', icon: Icons.play_arrow_rounded, onPressed: openThemes),
        if (latestStory != null) ...[const SizedBox(height: 16), _TonightCard(story: latestStory)],
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: IconTile(image: AppImages.iconBook, label: 'Thèmes', onTap: openThemes),
            ),
            Expanded(
              child: IconTile(image: AppImages.mascot, label: 'Personnages', onTap: () => context.push('/personnages')),
            ),
            Expanded(
              child: IconTile(
                image: AppImages.iconHeart,
                label: 'Mes histoires',
                onTap: () => context.push('/mes-histoires'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Dernière histoire, à relire ce soir (US-09).
class _TonightCard extends StatelessWidget {
  const _TonightCard({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/histoire/${story.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Image.asset(AppImages.iconBook, width: 44, excludeFromSemantics: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ce soir', style: textTheme.bodySmall),
                    Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

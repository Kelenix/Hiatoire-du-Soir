import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../offers/data/offers_repository.dart';
import '../data/catalog_repository.dart';
import 'theme_card.dart';

/// Choix du thème (US-04, US-27, maquette E2), puis options de création (E3). Premium ou crédits ouvrent les
/// thèmes payants (US-35).
class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key, this.heroId});

  /// Héros choisi dans « Personnages », transmis aux options.
  final String? heroId;

  static const _grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: .8,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    return NightScaffold(
      title: 'Choisis un thème',
      body: ref
          .watch(themesProvider)
          .when(
            data: (themes) => GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: _grid,
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isLocked = !(theme.isFree || (entitlements?.canUseTheme(theme) ?? false));
                return ThemeCard(
                  theme: theme,
                  isLocked: isLocked,
                  onTap: () => context.push(
                    isLocked
                        ? '/demande-parent'
                        : heroId == null
                        ? '/preparer/${theme.id}'
                        : '/preparer/${theme.id}?heros=$heroId',
                  ),
                );
              },
            ),
            loading: () => GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: _grid,
              itemCount: 6,
              itemBuilder: (_, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
            error: (_, _) => MascotState(
              title: 'Les thèmes se cachent…',
              message: 'Vérifie la connexion Internet, puis réessaie.',
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(themesProvider),
            ),
          ),
    );
  }
}

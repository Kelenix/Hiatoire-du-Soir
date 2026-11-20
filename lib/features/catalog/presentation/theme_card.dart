import 'package:flutter/material.dart';

import '../../../core/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/story_theme.dart';

/// Carte de thème : illustration du kit, nom, cadenas doré si le thème est verrouillé.
class ThemeCard extends StatelessWidget {
  const ThemeCard({super.key, required this.theme, required this.isLocked, required this.onTap});

  final StoryTheme theme;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = AppImages.illustration(theme.illustration);
    return Semantics(
      button: true,
      label: isLocked ? '${theme.name}, demande à un parent' : theme.name,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(gradient: AppGradients.tile),
                      // La mascotte (détourée) est montrée entière ; les scènes remplissent la carte.
                      child: Image.asset(image, fit: image == AppImages.mascot ? BoxFit.contain : BoxFit.cover),
                    ),
                    if (isLocked) const Positioned(top: 8, right: 8, child: _LockBadge()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  theme.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.night.withValues(alpha: .7),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .5), blurRadius: 12)],
      ),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.lock_rounded, color: AppColors.gold, size: 22),
      ),
    );
  }
}

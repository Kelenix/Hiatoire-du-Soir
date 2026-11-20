import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Histoires gratuites restantes cette semaine, en étoiles (US-03, H18). Aucun prix.
class StarsLeft extends StatelessWidget {
  const StarsLeft({super.key, required this.count, this.total = 3});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: count == 1 ? 'Encore 1 histoire cette semaine' : 'Encore $count histoires cette semaine',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < total; index++)
            Icon(
              index < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 34,
              color: index < count ? AppColors.gold : AppColors.lavender.withValues(alpha: .6),
              shadows: index < count ? [Shadow(color: AppColors.gold.withValues(alpha: .6), blurRadius: 12)] : null,
            ),
        ],
      ),
    );
  }
}

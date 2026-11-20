import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tuile d'icône du kit : carré arrondi en dégradé violet, icône 3D au centre, libellé dessous.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.image, required this.label, this.onTap, this.size = 88});

  final String image;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * .24);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.tile,
            borderRadius: radius,
            border: Border.all(color: AppColors.tileBorder, width: 1.5),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Semantics(
                button: true,
                label: label,
                child: SizedBox.square(
                  dimension: size,
                  child: Padding(
                    padding: EdgeInsets.all(size * .12),
                    child: Image.asset(image, excludeFromSemantics: true),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

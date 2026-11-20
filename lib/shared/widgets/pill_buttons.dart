import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const _height = 56.0;

/// Bouton principal du kit (« ▶ Créer une histoire ») : pilule en dégradé Magie, sans halo autour.
class MagicButton extends StatelessWidget {
  const MagicButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? .4 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.magic,
          borderRadius: BorderRadius.circular(_height),
        ),
        child: _PillContent(label: label, icon: icon, onPressed: onPressed, iconColor: Colors.white),
      ),
    );
  }
}

/// Bouton secondaire du kit (« 👑 Passer Premium ») : pilule transparente à contour lavande.
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? .4 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_height),
          border: Border.all(color: AppColors.outlineButton, width: 2),
        ),
        child: _PillContent(label: label, icon: icon, onPressed: onPressed, iconColor: AppColors.gold),
      ),
    );
  }
}

class _PillContent extends StatelessWidget {
  const _PillContent({required this.label, required this.icon, required this.onPressed, required this.iconColor});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
      color: Colors.white,
      shadows: [Shadow(color: AppColors.night.withValues(alpha: .35), blurRadius: 6, offset: const Offset(0, 1))],
    );
    // Annoncé comme un bouton à part entière par TalkBack / VoiceOver, sans se mêler au texte voisin.
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, color: iconColor, size: 28), const SizedBox(width: 10)],
                  Flexible(
                    child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

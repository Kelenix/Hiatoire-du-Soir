import 'package:flutter/material.dart';

import '../../core/app_images.dart';
import 'pill_buttons.dart';

/// État vide, erreur ou hors connexion, porté par la mascotte (design system §4).
class MascotState extends StatelessWidget {
  const MascotState({super.key, required this.title, required this.message, this.actionLabel, this.onAction});

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppImages.mascot, width: 160, excludeFromSemantics: true),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 32),
              OutlinePillButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

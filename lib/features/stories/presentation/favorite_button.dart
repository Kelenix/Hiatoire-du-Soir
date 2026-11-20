import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../application/favorites_providers.dart';
import '../domain/story.dart';

/// Bouton rond ♥ du kit (US-13, US-14).
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteProvider(story));
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        button: true,
        label: isFavorite ? 'Retirer de mes histoires' : 'Garder cette histoire',
        excludeSemantics: true,
        child: Material(
          color: AppColors.roundButtonFill,
          shape: const CircleBorder(side: BorderSide(color: AppColors.roundButtonBorder, width: 1.5)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _toggle(context, ref),
            child: SizedBox.square(
              dimension: 48,
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.heart,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(favoriteProvider(story).notifier).toggle();
    if (failure == null || !context.mounted) return;
    if (failure == Failure.favoritesLimit) {
      await showDialog<void>(context: context, builder: (_) => const _FullLibraryDialog());
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le cœur n’a pas pu être enregistré. Réessaie dans un instant.')));
    }
  }
}

/// Bibliothèque pleine en gratuit : retirer une histoire ou demander à un parent (US-14).
class _FullLibraryDialog extends StatelessWidget {
  const _FullLibraryDialog();

  @override
  Widget build(BuildContext context) {
    void goTo(String location) {
      Navigator.of(context).pop();
      context.push(location);
    }

    return AlertDialog(
      title: const Text('Ta bibliothèque est pleine'),
      content: const Text('Tu gardes déjà 3 histoires. Retire-en une dans « Mes histoires », ou demande à un parent.'),
      actions: [
        TextButton(onPressed: () => goTo('/mes-histoires'), child: const Text('Mes histoires')),
        TextButton(onPressed: () => goTo('/demande-parent'), child: const Text('Demander à un parent')),
      ],
    );
  }
}

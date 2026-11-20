import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/option_chip.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../offers/data/offers_repository.dart';
import '../data/characters_repository.dart';
import '../domain/character.dart';

/// Personnages (US-30, US-31, maquette E7) : la famille d'abord, puis les héros des thèmes.
/// Choisir un héros mène aux thèmes, puis aux options avec ce héros.
class CharactersScreen extends ConsumerWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(entitlementsProvider).valueOrNull?.isPremium ?? false;
    void chooseHero(Character hero) => context.push('/themes?heros=${hero.id}');
    return NightScaffold(
      title: 'Personnages',
      body: ref
          .watch(charactersProvider)
          .when(
            data: (characters) {
              final family = characters.where((character) => character.isFamily).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  const SectionTitle('Ta famille'),
                  if (family.isEmpty) ...[
                    Text(
                      'Avec un parent, crée ton personnage : il deviendra le héros de tes histoires.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    OutlinePillButton(
                      label: 'Créer avec un parent',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/parents/personnages'),
                    ),
                  ] else
                    _CharacterGrid(
                      characters: family,
                      isLocked: !isPremium,
                      onTap: isPremium ? chooseHero : (_) => context.push('/demande-parent'),
                    ),
                  const SectionTitle('Les héros des histoires'),
                  _CharacterGrid(
                    characters: characters.where((character) => !character.isFamily).toList(),
                    onTap: chooseHero,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => MascotState(
              title: 'Les personnages se cachent…',
              message: 'Vérifie la connexion Internet, puis réessaie.',
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(charactersProvider),
            ),
          ),
    );
  }
}

class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid({required this.characters, required this.onTap, this.isLocked = false});

  final List<Character> characters;
  final bool isLocked;
  final void Function(Character character) onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
      for (final character in characters)
        _CharacterCard(character: character, isLocked: isLocked, onTap: () => onTap(character)),
    ],
  );
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character, required this.isLocked, required this.onTap});

  final Character character;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: isLocked ? '${character.name}, demande à un parent' : character.name,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Text(character.animal.emoji, style: const TextStyle(fontSize: 44)),
                      if (isLocked)
                        const Positioned(
                          right: -10,
                          bottom: 0,
                          child: Icon(Icons.lock_rounded, size: 20, color: AppColors.gold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
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

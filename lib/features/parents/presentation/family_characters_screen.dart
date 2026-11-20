import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_action_layout.dart';
import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/option_chip.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../characters/data/characters_repository.dart';
import '../../characters/domain/character.dart';
import '../../offers/data/offers_repository.dart';

const _maxCharacters = 10;

/// Personnages de la famille (US-30, maquette P5).
class FamilyCharactersScreen extends ConsumerWidget {
  const FamilyCharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(entitlementsProvider).valueOrNull?.isPremium ?? false;
    final textTheme = Theme.of(context).textTheme;
    return NightScaffold(
      title: 'Personnages',
      body: ref
          .watch(charactersProvider)
          .when(
            data: (characters) {
              final family = characters.where((character) => character.isFamily).toList();
              return BottomActionLayout(
                content: [
                  Text(
                    'Le personnage de votre enfant devient le héros des histoires. Son prénom reste chez nous : '
                    'il n’est jamais envoyé au service qui écrit les histoires.',
                    style: textTheme.bodyMedium,
                  ),
                  if (!isPremium) ...[
                    const SizedBox(height: 8),
                    Text('Les histoires avec ces personnages font partie de Premium.', style: textTheme.bodySmall),
                  ],
                  const SizedBox(height: 20),
                  for (final character in family) _CharacterTile(character: character),
                  if (family.length >= _maxCharacters) ...[
                    const SizedBox(height: 8),
                    Text('$_maxCharacters personnages au maximum.', style: textTheme.bodySmall),
                  ],
                ],
                action: MagicButton(
                  label: 'Ajouter un personnage',
                  icon: Icons.add_rounded,
                  onPressed: family.length < _maxCharacters ? () => context.push('/parents/personnages/edition') : null,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => MascotState(
              title: 'Les personnages se cachent…',
              message: 'Vérifiez la connexion Internet, puis réessayez.',
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(charactersProvider),
            ),
          ),
    );
  }
}

class _CharacterTile extends ConsumerWidget {
  const _CharacterTile({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/parents/personnages/edition', extra: character),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                Text(character.animal.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(character.name, style: textTheme.titleMedium),
                      Text(
                        '${character.gender.label} · ${character.animal.label} · ${character.trait.label}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer ${character.name}',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Supprimer ${character.name} ?'),
        content: const Text('Les histoires déjà créées avec ce personnage restent dans « Mes histoires ».'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure = await ref.read(characterEditorProvider).delete(character.id);
    if (failure != null && context.mounted) _showFailure(context, failure);
  }
}

/// Création ou modification d'un personnage (US-30, maquette P5).
class CharacterFormScreen extends ConsumerStatefulWidget {
  const CharacterFormScreen({super.key, this.character});

  /// Absent : nouveau personnage.
  final Character? character;

  @override
  ConsumerState<CharacterFormScreen> createState() => _CharacterFormScreenState();
}

class _CharacterFormScreenState extends ConsumerState<CharacterFormScreen> {
  late final _name = TextEditingController(text: widget.character?.name);
  late HeroGender? _gender = widget.character?.gender;
  late Animal? _animal = widget.character?.animal;
  late Trait? _trait = widget.character?.trait;
  var _isSaving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (gender, animal, trait) = (_gender, _animal, _trait);
    final name = _name.text.trim();
    final canSave = name.isNotEmpty && gender != null && animal != null && trait != null && !_isSaving;
    return NightScaffold(
      title: widget.character == null ? 'Nouveau personnage' : 'Modifier le personnage',
      body: BottomActionLayout(
        content: [
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Prénom ou surnom'),
          ),
          const SectionTitle('Accords dans l’histoire'),
          OptionWrap(
            children: [
              for (final value in HeroGender.values)
                OptionChip(
                  label: value.label,
                  isSelected: gender == value,
                  onTap: () => setState(() => _gender = value),
                ),
            ],
          ),
          const SectionTitle('Animal compagnon'),
          OptionWrap(
            children: [
              for (final value in Animal.values)
                OptionChip(
                  label: value.label,
                  emoji: value.emoji,
                  isSelected: animal == value,
                  onTap: () => setState(() => _animal = value),
                ),
            ],
          ),
          const SectionTitle('Caractère'),
          OptionWrap(
            children: [
              for (final value in Trait.values)
                OptionChip(
                  label: value.label,
                  emoji: value.emoji,
                  isSelected: trait == value,
                  onTap: () => setState(() => _trait = value),
                ),
            ],
          ),
        ],
        action: MagicButton(
          label: 'Enregistrer',
          icon: Icons.check_rounded,
          onPressed: canSave ? () => _save((name: name, gender: gender, animal: animal, trait: trait)) : null,
        ),
      ),
    );
  }

  Future<void> _save(CharacterDraft draft) async {
    setState(() => _isSaving = true);
    final failure = await ref.read(characterEditorProvider).save(widget.character?.id, draft);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (failure == null) {
      context.pop();
    } else {
      _showFailure(context, failure);
    }
  }
}

void _showFailure(BuildContext context, Failure failure) {
  final message = switch (failure) {
    Failure.charactersLimit => '$_maxCharacters personnages au maximum : supprimez-en un pour en créer un autre.',
    Failure.offline || Failure.timeout => 'Pas de connexion Internet. Réessayez.',
    _ => 'L’enregistrement a échoué. Réessayez.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

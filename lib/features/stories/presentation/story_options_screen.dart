import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/bottom_action_layout.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/option_chip.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../characters/data/characters_repository.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../characters/domain/character.dart';
import '../../offers/data/offers_repository.dart';

/// Options de création (US-27, US-31, US-32, US-35, maquette E3). Sans Premium ni crédit adapté, seuls
/// les héros prêts à l'emploi et 2 minutes sont ouverts ; le serveur revérifie chaque droit.
class StoryOptionsScreen extends ConsumerStatefulWidget {
  const StoryOptionsScreen({super.key, required this.themeId, this.heroId});

  final String themeId;

  /// Héros choisi dans « Personnages » ; sinon, celui du thème s'il en a un.
  final String? heroId;

  @override
  ConsumerState<StoryOptionsScreen> createState() => _StoryOptionsScreenState();
}

class _StoryOptionsScreenState extends ConsumerState<StoryOptionsScreen> {
  String? _heroId;
  var _isHeroChosen = false;
  Animal? _animal;
  String? _situationId;
  var _isOwnSituation = false;
  final _situationText = TextEditingController();
  var _durationMin = 2;

  @override
  void dispose() {
    _situationText.dispose();
    super.dispose();
  }

  void _askParent() => context.push('/demande-parent');

  @override
  Widget build(BuildContext context) {
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    final theme = ref.watch(themesProvider).valueOrNull?.where((theme) => theme.id == widget.themeId).firstOrNull;
    final characters = ref.watch(charactersProvider).valueOrNull ?? const <Character>[];
    final situations = ref.watch(situationsProvider).valueOrNull ?? const <Situation>[];
    final heroId = _isHeroChosen
        ? _heroId
        : widget.heroId ?? characters.where((character) => character.themeId == widget.themeId).firstOrNull?.id;
    final isFamilyHero = characters.any((character) => character.id == heroId && character.isFamily);
    final isPersonalized = isFamilyHero || _animal != null || _situationId != null || _isOwnSituation;
    final isPremium = entitlements?.isPremium ?? false;
    final canPersonalize = isPremium || (theme != null && (entitlements?.canPersonalize(theme) ?? false));
    final canChooseDuration =
        isPremium || (theme != null && (entitlements?.canChooseDuration(theme, personalized: isPersonalized) ?? false));
    // Option retirée (animal, situation) : une durée qui n'est plus permise revient à 2 minutes.
    final durationMin = canChooseDuration ? _durationMin : 2;
    VoidCallback unlockedIf(bool isAllowed, VoidCallback choose) => isAllowed ? () => setState(choose) : _askParent;
    final ownText = _situationText.text.trim();

    return NightScaffold(
      title: 'Prépare ton histoire',
      body: BottomActionLayout(
        content: [
          const SectionTitle('Le héros'),
          OptionWrap(
            children: [
              OptionChip(label: 'Surprise', emoji: '✨', isSelected: heroId == null, onTap: () => _chooseHero(null)),
              for (final character in characters)
                OptionChip(
                  label: character.name,
                  emoji: character.animal.emoji,
                  isSelected: heroId == character.id,
                  isLocked: character.isFamily && !canPersonalize,
                  onTap: character.isFamily && !canPersonalize ? _askParent : () => _chooseHero(character.id),
                ),
            ],
          ),
          const SectionTitle('Un animal'),
          OptionWrap(
            children: [
              OptionChip(label: 'Aucun', isSelected: _animal == null, onTap: () => setState(() => _animal = null)),
              for (final animal in Animal.values)
                OptionChip(
                  label: animal.label,
                  emoji: animal.emoji,
                  isSelected: _animal == animal,
                  isLocked: !canPersonalize,
                  onTap: unlockedIf(canPersonalize, () => _animal = animal),
                ),
            ],
          ),
          const SectionTitle('Une situation'),
          OptionWrap(
            children: [
              OptionChip(
                label: 'Aucune',
                isSelected: _situationId == null && !_isOwnSituation,
                onTap: () => setState(() => _chooseSituation(null)),
              ),
              for (final situation in situations)
                OptionChip(
                  label: situation.label,
                  isSelected: _situationId == situation.id,
                  isLocked: !canPersonalize,
                  onTap: unlockedIf(canPersonalize, () => _chooseSituation(situation.id)),
                ),
              OptionChip(
                label: 'Je la raconte',
                emoji: '✏️',
                isSelected: _isOwnSituation,
                isLocked: !canPersonalize,
                onTap: unlockedIf(canPersonalize, () => _chooseSituation(null, isOwn: true)),
              ),
            ],
          ),
          if (_isOwnSituation) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _situationText,
              maxLength: 150,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Ce que vit l’enfant',
                helperText: 'Ex. : demain, c’est la rentrée. Sans nom ni adresse.',
                helperMaxLines: 2,
              ),
            ),
          ],
          const SectionTitle('Durée'),
          OptionWrap(
            children: [
              for (final minutes in const [2, 5, 10])
                OptionChip(
                  label: '$minutes minutes',
                  isSelected: durationMin == minutes,
                  isLocked: minutes != 2 && !canChooseDuration,
                  onTap: minutes == 2
                      ? () => setState(() => _durationMin = 2)
                      : unlockedIf(canChooseDuration, () => _durationMin = minutes),
                ),
            ],
          ),
        ],
        action: MagicButton(
          label: 'Créer l’histoire',
          icon: Icons.auto_awesome_rounded,
          onPressed: _isOwnSituation && ownText.length < 3
              ? null
              : () => context.push(
                  '/creer/${widget.themeId}',
                  extra: (
                    durationMin: durationMin,
                    characterId: heroId,
                    animal: _animal,
                    situationId: _situationId,
                    situationText: _isOwnSituation ? ownText : null,
                  ),
                ),
        ),
      ),
    );
  }

  void _chooseHero(String? id) => setState(() {
    _heroId = id;
    _isHeroChosen = true;
  });

  void _chooseSituation(String? id, {bool isOwn = false}) {
    _situationId = id;
    _isOwnSituation = isOwn;
  }
}

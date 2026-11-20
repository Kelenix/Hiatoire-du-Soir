import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/features/characters/domain/character.dart';
import 'package:histoires_du_soir/features/offers/data/offers_repository.dart';
import 'package:histoires_du_soir/features/offers/domain/credits.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';

import '../../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Amène l'élément au milieu de l'écran (pas sous la barre de titre), puis le touche.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  final element = tester.element(finder);
  if (Scrollable.maybeOf(element) != null) await Scrollable.ensureVisible(element, alignment: .5);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

const _premium = Entitlements(freeStoriesLeft: 3, isPremium: true, isAnonymous: false);
const _askParent = 'Demande à un parent de venir t’aider.';

void main() {
  testWidgets('gratuit : les options sur mesure demandent un parent (US-32)', (tester) async {
    await pumpApp(tester, location: '/preparer/animaux', characters: FakeCharactersRepository([lea]));

    await _tap(tester, find.text('🐶  Chien'));

    expect(find.text(_askParent), findsOneWidget);
  });

  testWidgets('gratuit : un personnage de la famille demande un parent (US-30)', (tester) async {
    await pumpApp(tester, location: '/personnages', characters: FakeCharactersRepository([lea]));

    await _tap(tester, find.bySemanticsLabel('Léa, demande à un parent'));

    expect(find.text(_askParent), findsOneWidget);
  });

  testWidgets('Premium : personnage de la famille, animal et situation racontée par le parent (US-32)', (tester) async {
    final stories = FakeStoryRepository();
    await pumpApp(
      tester,
      location: '/preparer/animaux',
      entitlements: () => _premium,
      characters: FakeCharactersRepository([lea]),
      stories: stories,
    );

    await _tap(tester, find.text('🐰  Léa'));
    await _tap(tester, find.text('🦄  Licorne'));
    await _tap(tester, find.text('✏️  Je la raconte'));
    await tester.enterText(find.byType(TextField), '  Demain, c’est la rentrée  ');
    await _tap(tester, find.text('Créer l’histoire'));

    expect(stories.requests.single.options, (
      durationMin: 2,
      characterId: lea.id,
      animal: Animal.licorne,
      situationId: null,
      situationText: 'Demain, c’est la rentrée',
    ));
    expect(find.text(testStory.title), findsOneWidget);
  });

  testWidgets('option retirée : la durée qu’elle permettait revient à 2 minutes', (tester) async {
    final stories = FakeStoryRepository();
    await pumpApp(
      tester,
      location: '/preparer/animaux',
      entitlements: () => const Entitlements(freeStoriesLeft: 0, isAnonymous: false, credits: {CreditScope.custom: 1}),
      stories: stories,
    );

    await _tap(tester, find.text('🦄  Licorne'));
    await _tap(tester, find.text('10 minutes'));
    await _tap(tester, find.text('Aucun'));
    await _tap(tester, find.text('Créer l’histoire'));

    expect(stories.requests.single.options.durationMin, 2);
  });

  testWidgets('Personnages → thème → options avec ce héros (US-31)', (tester) async {
    final stories = FakeStoryRepository();
    await pumpApp(tester, location: '/', entitlements: () => _premium, stories: stories);

    await _tap(tester, find.bySemanticsLabel('Personnages'));
    await _tap(tester, find.bySemanticsLabel('Pipo'));
    await _tap(tester, find.bySemanticsLabel('Océan'));
    await _tap(tester, find.text('Créer l’histoire'));

    expect(stories.requests.single.options.characterId, pipo.id);
  });

  testWidgets('sans personnage de la famille : invitation à le créer avec un parent (E7)', (tester) async {
    await pumpApp(tester, location: '/personnages');

    await _tap(tester, find.text('Créer avec un parent'));

    expect(find.text('Espace réservé aux parents'), findsOneWidget);
  });

  testWidgets('Espace Parents : créer, modifier puis supprimer un personnage (US-30)', (tester) async {
    final container = await pumpApp(tester);
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/personnages');

    await _tap(tester, find.text('Ajouter un personnage'));
    await tester.enterText(find.byType(TextField), 'Tom');
    await _tap(tester, find.text('Garçon'));
    await _tap(tester, find.text('🐶  Chien'));
    await _tap(tester, find.text('🦁  Courage'));
    await _tap(tester, find.text('Enregistrer'));
    expect(find.text('Garçon · Chien · Courage'), findsOneWidget);

    await _tap(tester, find.text('Tom'));
    await _tap(tester, find.text('Neutre'));
    await _tap(tester, find.text('Enregistrer'));
    expect(find.text('Neutre · Chien · Courage'), findsOneWidget);

    await _tap(tester, find.byTooltip('Supprimer Tom'));
    await _tap(tester, find.text('Supprimer'));
    expect(find.text('Tom'), findsNothing);
  });

  testWidgets('Espace Parents : le 11ᵉ personnage est refusé avec une explication (US-30)', (tester) async {
    final characters = FakeCharactersRepository()..saveFailure = Failure.charactersLimit;
    final container = await pumpApp(tester, characters: characters);
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/personnages/edition');

    await tester.enterText(find.byType(TextField), 'Zoé');
    await _tap(tester, find.text('Fille'));
    await _tap(tester, find.text('🐱  Chat'));
    await _tap(tester, find.text('🧸  Douceur'));
    await _tap(tester, find.text('Enregistrer'));

    expect(find.textContaining('10 personnages au maximum'), findsOneWidget);
  });
}

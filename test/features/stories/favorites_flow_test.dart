import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/features/stories/domain/story.dart';

import '../../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('le cœur garde l’histoire, retrouvée dans « Mes histoires » (US-13, US-15)', (tester) async {
    final stories = FakeStoryRepository();
    await pumpApp(tester, location: '/histoire/${testStory.id}', stories: stories);

    await tester.tap(find.bySemanticsLabel('Garder cette histoire'));
    await _settle(tester);

    expect(find.bySemanticsLabel('Retirer de mes histoires'), findsOneWidget);
    expect(stories.favoriteStories, [testStory]);

    await pumpApp(tester, location: '/mes-histoires', stories: stories);
    expect(find.text(testStory.title), findsOneWidget);
  });

  testWidgets('double appui sur le cœur : une seule demande, état fidèle au serveur', (tester) async {
    final stories = FakeStoryRepository()..favoriteDelay = const Duration(milliseconds: 300);
    await pumpApp(tester, location: '/histoire/${testStory.id}', stories: stories);

    await tester.tap(find.bySemanticsLabel('Garder cette histoire'));
    await tester.tap(find.bySemanticsLabel('Garder cette histoire'));
    await _settle(tester);

    expect(stories.favoriteStories, [testStory]);
    expect(find.bySemanticsLabel('Retirer de mes histoires'), findsOneWidget);
  });

  testWidgets('bibliothèque pleine : message doux, rien n’est gardé (US-14)', (tester) async {
    final stories = FakeStoryRepository()..favoriteFailure = Failure.favoritesLimit;
    await pumpApp(tester, location: '/histoire/${testStory.id}', stories: stories);

    await tester.tap(find.bySemanticsLabel('Garder cette histoire'));
    await _settle(tester);

    expect(find.text('Ta bibliothèque est pleine'), findsOneWidget);
    expect(find.text('Demander à un parent'), findsOneWidget);
    expect(find.bySemanticsLabel('Garder cette histoire'), findsOneWidget);
  });

  testWidgets('aucun favori : état vide illustré (US-15)', (tester) async {
    await pumpApp(tester, location: '/mes-histoires');

    expect(find.text('Aucune histoire gardée'), findsOneWidget);
  });

  testWidgets('favoris chargés par pages de 20 (US-15)', (tester) async {
    final stories = FakeStoryRepository();
    stories.favoriteStories.addAll(
      List.generate(
        25,
        (index) =>
            Story(id: 'h$index', themeId: 'animaux', durationMin: 2, title: 'Histoire $index', paragraphs: const ['p']),
      ),
    );
    await pumpApp(tester, location: '/mes-histoires', stories: stories);

    await tester.scrollUntilVisible(find.text('Voir plus'), 300);
    await tester.tap(find.text('Voir plus'));
    await _settle(tester);
    await tester.scrollUntilVisible(find.text('Histoire 24'), 300);

    expect(find.text('Histoire 24'), findsOneWidget);
    expect(find.text('Voir plus'), findsNothing);
  });
}

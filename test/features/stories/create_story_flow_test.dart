import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';

import '../../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('thème gratuit → options → création → lecture de l’histoire (US-04, US-05, US-08)', (tester) async {
    final stories = FakeStoryRepository();
    await pumpApp(tester, location: '/themes', stories: stories);

    await tester.tap(find.bySemanticsLabel('Animaux'));
    await _settle(tester);
    await tester.tap(find.text('Créer l’histoire'));
    await _settle(tester);

    expect(stories.requests.single.options, (
      durationMin: 2,
      characterId: pipo.id,
      animal: null,
      situationId: null,
      situationText: null,
    ), reason: 'le héros du thème est proposé par défaut (US-31)');
    expect(find.text(testStory.title), findsOneWidget);
    expect(find.text(testStory.paragraphs.last), findsOneWidget);
  });

  testWidgets('thème verrouillé → « Demande à un parent », sans prix (US-04)', (tester) async {
    await pumpApp(tester, location: '/themes');

    await tester.tap(find.bySemanticsLabel('Océan, demande à un parent'));
    await _settle(tester);

    expect(find.text('Demande à un parent de venir t’aider.'), findsOneWidget);
  });

  testWidgets('quota atteint → « Demande à un parent » (US-07)', (tester) async {
    await pumpApp(tester, location: '/creer/animaux', stories: FakeStoryRepository([Failure.quotaReached]));
    await _settle(tester);

    expect(find.text('Demande à un parent de venir t’aider.'), findsOneWidget);
  });

  testWidgets('échec → « Réessayer » rejoue la même demande (US-06)', (tester) async {
    final stories = FakeStoryRepository([Failure.contentRejected, testStory]);
    await pumpApp(tester, location: '/creer/animaux', stories: stories);
    await _settle(tester);

    expect(find.textContaining('rien n’a été décompté'), findsOneWidget);

    stories.pending = Completer<void>();
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(find.textContaining('rien n’a été décompté'), findsNothing, reason: 'l’animation remplace l’erreur');
    stories.pending!.complete();
    await _settle(tester);

    expect(find.text(testStory.title), findsOneWidget);
    expect(stories.requests, hasLength(2));
    expect(stories.requests.map((request) => request.requestId).toSet(), hasLength(1));
  });
}

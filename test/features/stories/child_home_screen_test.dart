import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  testWidgets("présente l'accueil Enfant du kit (US-02)", (tester) async {
    await pumpApp(tester);

    expect(find.bySemanticsLabel('Histoires du Soir'), findsOneWidget);
    expect(find.text('Créer une histoire'), findsOneWidget);
    for (final label in ['Thèmes', 'Personnages', 'Mes histoires', 'Parents']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
  });

  testWidgets('montre les histoires gratuites restantes en étoiles (US-03)', (tester) async {
    await pumpApp(tester, freeStoriesLeft: 2);

    expect(find.bySemanticsLabel('Encore 2 histoires cette semaine'), findsOneWidget);
  });

  testWidgets('propose de relire la dernière histoire (US-09)', (tester) async {
    await pumpApp(tester, latestStory: testStory);

    await tester.tap(find.text(testStory.title));
    await tester.pump();
    await tester.pump();

    expect(find.text(testStory.paragraphs.first), findsOneWidget);
  });

  testWidgets("aucun prix, achat ni publicité dans l'Espace Enfant (US-02, NF-01)", (tester) async {
    await pumpApp(tester, latestStory: testStory);

    final forbidden = RegExp(r'€|\$|prix|acheter|achat|premium|abonnement|publicité', caseSensitive: false);
    final texts = tester.widgetList<Text>(find.byType(Text)).map((text) => text.data ?? '');
    expect(texts.where(forbidden.hasMatch), isEmpty);
  });

  testWidgets('tient sur un petit téléphone sans débordement (NF-08)', (tester) async {
    await pumpApp(tester, latestStory: testStory, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
  });
}

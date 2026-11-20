import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';
import 'package:histoires_du_soir/features/session/data/session_repository.dart';
import 'package:histoires_du_soir/features/stories/data/story_repository.dart';

import '../../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _FakeSession extends Fake implements SessionRepository {
  @override
  Future<EmailCodePurpose> sendEmailCode(String email) async => EmailCodePurpose.linkThisDevice;
}

void main() {
  testWidgets('signaler : contrôle parental, motif, histoire retirée (US-22)', (tester) async {
    final stories = FakeStoryRepository();
    await pumpApp(tester, location: '/histoire/${testStory.id}', stories: stories);

    await tester.tap(find.byTooltip('Signaler cette histoire (parents)'));
    await _settle(tester);
    await solveParentalGate(tester);
    await _settle(tester);

    expect(find.text('Signaler l’histoire'), findsOneWidget);
    await tester.tap(find.text(ReportReason.scary.label));
    await tester.pump();
    await tester.tap(find.text('Envoyer le signalement'));
    await _settle(tester);

    expect(stories.reports.single.$1, testStory.id);
    expect(stories.reports.single.$2, ReportReason.scary);
    expect(find.text('Créer une histoire'), findsOneWidget);
  });

  testWidgets('réglage « texte grand » appliqué à la lecture (US-18)', (tester) async {
    final container = await pumpApp(tester, location: '/');
    container.read(parentalGateProvider.notifier).unlock();

    await goTo(tester, '/parents/parametres');
    await tester.tap(find.text('Grand'));
    await _settle(tester);
    await goTo(tester, '/histoire/${testStory.id}');

    final paragraph = tester.widget<Text>(find.text(testStory.paragraphs.first));
    expect(paragraph.style!.fontSize, 24);
  });

  testWidgets('code e-mail en attente : retrouvé après la fermeture de l’Espace Parents (H22)', (tester) async {
    final container = await pumpApp(tester, overrides: [sessionRepositoryProvider.overrideWithValue(_FakeSession())]);
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/compte');
    await tester.enterText(find.byType(TextField), 'parent@exemple.fr');
    await tester.tap(find.text('Recevoir un code'));
    await _settle(tester);
    expect(find.text('Valider le code'), findsOneWidget);

    await goTo(tester, '/');
    await goTo(tester, '/parents/compte');
    await _settle(tester);

    expect(find.text('Valider le code'), findsOneWidget);
    expect(find.text('parent@exemple.fr'), findsOneWidget);
  });

  testWidgets('accueil Parents : sections disponibles, aucune en double (US-17)', (tester) async {
    final container = await pumpApp(tester, location: '/');
    container.read(parentalGateProvider.notifier).unlock();

    await goTo(tester, '/parents');

    await tester.pump(const Duration(seconds: 1)); // fin de la transition : l'accueil Enfant passe hors écran
    expect(find.textContaining('Encore 3 histoires gratuites'), findsOneWidget);
    for (final section in [
      'Offre gratuite',
      'Packs d’histoires et de voix',
      'Personnages',
      'Compte',
      'Réglages de lecture',
      'Aide et support',
    ]) {
      await tester.scrollUntilVisible(find.text(section), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(section), findsOneWidget);
    }
  });
}

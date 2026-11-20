import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';

import '../../helpers.dart';

void main() {
  test('nombres en toutes lettres (orthographe traditionnelle)', () {
    expect([11, 17, 21, 32, 40, 49].map(frenchNumber), [
      'onze',
      'dix-sept',
      'vingt et un',
      'trente-deux',
      'quarante',
      'quarante-neuf',
    ]);
  });

  test('le défi n’accepte que la bonne somme', () {
    final challenge = ParentalChallenge(Random(1));

    expect(challenge.question, contains(frenchNumber(challenge.left)));
    expect(challenge.isAnsweredBy('${challenge.left + challenge.right}'), isTrue);
    expect(challenge.isAnsweredBy('${challenge.left + challenge.right + 1}'), isFalse);
    expect(challenge.isAnsweredBy(''), isFalse);
  });

  testWidgets('Espace Parents verrouillé : défi, puis accès après la bonne réponse (US-16)', (tester) async {
    final container = await pumpApp(tester, location: '/parents');
    expect(find.text('Espace réservé aux parents'), findsOneWidget);

    await solveParentalGate(tester);

    expect(find.text('Espace Parents'), findsOneWidget);
    expect(container.read(parentalGateProvider.notifier).isUnlocked, isTrue);
  });

  testWidgets('trois erreurs : retour à l’Espace Enfant (US-16)', (tester) async {
    await pumpApp(tester, location: '/parents');

    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.tap(find.bySemanticsLabel('0'));
      await tester.pump();
      await tester.tap(find.text('Valider'));
      await tester.pump();
      await tester.pump();
    }

    expect(find.text('Créer une histoire'), findsOneWidget);
    expect(find.text('Espace Parents'), findsNothing);
  });
}

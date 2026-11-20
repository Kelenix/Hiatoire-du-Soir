import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/features/offers/data/offers_repository.dart';
import 'package:histoires_du_soir/features/offers/domain/premium_plan.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';

import '../../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _premium = Entitlements(freeStoriesLeft: 3, isPremium: true, isAnonymous: false);
const _freeAccount = Entitlements(freeStoriesLeft: 3, isAnonymous: false);

void main() {
  test('économie de l’annuel calculée sur les prix du store (34,99 € contre 12 × 5,99 €)', () {
    expect(annualSavingsPercent(annual: testPlans.first, monthly: testPlans.last), 51);
    // Typographie française : espace insécable avant le symbole monétaire.
    expect(testPlans.first.monthlyEquivalent, matches(RegExp(r'^2,92\s€$')));
  });

  test('droits lus tels que le serveur les renvoie', () {
    final entitlements = Entitlements.fromJson({
      'free_stories_left': 0,
      'is_premium': true,
      'premium_until': '2027-11-20T20:00:00+00:00',
      'is_anonymous': false,
    });

    expect(entitlements.isPremium, isTrue);
    expect(entitlements.premiumUntil, isNotNull);
    expect(entitlements.isAnonymous, isFalse);
  });

  testWidgets('offre : formules du store, essai gratuit, achat de l’annuel (US-24, US-25)', (tester) async {
    final purchases = FakePurchasesRepository();
    var entitlements = _freeAccount;
    final container = await pumpApp(tester, location: '/', entitlements: () => entitlements, purchases: purchases);
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/premium');
    await _settle(tester);

    expect(find.text('Créez des histoires illimitées pour votre enfant.'), findsOneWidget);
    expect(find.text('34,99 € / an'), findsOneWidget);
    expect(find.textContaining(RegExp(r'soit 2,92\s€ / mois  ·  −51 %')), findsOneWidget);
    expect(find.text('5,99 € / mois'), findsOneWidget);

    entitlements = _premium;
    await tester.ensureVisible(find.text('Essayer 7 jours gratuits'));
    await tester.pump();
    await tester.tap(find.text('Essayer 7 jours gratuits'));
    await _settle(tester);

    expect(purchases.purchased.single.period, PlanPeriod.annual);
    expect(find.text('Espace Parents'), findsOneWidget);
  });

  testWidgets('sans compte parent : création du compte demandée avant l’achat (US-25)', (tester) async {
    final container = await pumpApp(tester, location: '/');
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/premium');
    await _settle(tester);

    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.text('Essayer 7 jours gratuits'), findsNothing);
  });

  testWidgets('« Demande à un parent » mène à l’offre, derrière le contrôle parental (US-28)', (tester) async {
    await pumpApp(tester, location: '/demande-parent');

    await tester.tap(find.text('Je suis le parent'));
    await _settle(tester);

    expect(find.text('Espace réservé aux parents'), findsOneWidget);
  });

  testWidgets('Premium : tous les thèmes ouverts et durée au choix (US-27)', (tester) async {
    final stories = FakeStoryRepository();
    await pumpApp(tester, location: '/themes', entitlements: () => _premium, stories: stories);

    expect(find.bySemanticsLabel('Océan, demande à un parent'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Océan'));
    await _settle(tester);
    await tester.ensureVisible(find.text('10 minutes'));
    await tester.pump();
    await tester.tap(find.text('10 minutes'));
    await tester.pump();
    await tester.tap(find.text('Créer l’histoire'));
    await _settle(tester);

    expect(stories.requests.single.options.durationMin, 10);
    expect(find.text(testStory.title), findsOneWidget);
  });

  testWidgets('Premium : pas de compteur d’histoires sur l’accueil (US-03)', (tester) async {
    await pumpApp(tester, entitlements: () => _premium);

    expect(find.bySemanticsLabel(RegExp('Encore .* cette semaine')), findsNothing);
  });
}

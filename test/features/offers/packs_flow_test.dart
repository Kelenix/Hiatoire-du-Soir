import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/features/catalog/domain/story_theme.dart';
import 'package:histoires_du_soir/features/offers/data/offers_repository.dart';
import 'package:histoires_du_soir/features/offers/domain/credits.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';

import '../../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openParents(
  WidgetTester tester,
  String location, {
  Entitlements Function()? entitlements,
  FakePurchasesRepository? purchases,
}) async {
  final container = await pumpApp(tester, entitlements: entitlements, purchases: purchases);
  container.read(parentalGateProvider.notifier).unlock();
  await goTo(tester, location);
  await _settle(tester);
}

const _account = Entitlements(freeStoriesLeft: 0, isAnonymous: false);

Entitlements _withCredits(Map<CreditScope, int> credits) =>
    Entitlements(freeStoriesLeft: 0, isAnonymous: false, credits: credits);

const _noel = StoryTheme(id: 'noel', name: 'Noël', tier: ThemeTier.seasonal, illustration: 'castle');
const _ocean = StoryTheme(id: 'ocean', name: 'Océan', tier: ThemeTier.premium, illustration: 'castle');
const _animaux = StoryTheme(id: 'animaux', name: 'Animaux', tier: ThemeTier.free, illustration: 'mascot');

void main() {
  test('les crédits se consomment dans l’ordre du serveur (H8, H16)', () {
    final all = _withCredits({
      CreditScope.noel: 1,
      CreditScope.premiumThemes: 1,
      CreditScope.custom: 1,
      CreditScope.generic: 1,
    });
    expect(all.creditFor(_noel, personalized: true), CreditScope.noel);
    expect(all.creditFor(_ocean, personalized: false), CreditScope.premiumThemes);
    expect(all.creditFor(_ocean, personalized: true), CreditScope.custom);
    expect(all.creditFor(_animaux, personalized: false), CreditScope.generic);

    final adventures = _withCredits({CreditScope.premiumThemes: 10});
    expect(adventures.canUseTheme(_ocean), isTrue);
    expect(adventures.canPersonalize(_ocean), isFalse);
    expect(adventures.canUseTheme(_noel), isFalse, reason: 'thèmes saisonniers exclus');
  });

  test('soldes lus tels que le serveur les renvoie', () {
    final entitlements = Entitlements.fromJson({
      'free_stories_left': 0,
      'is_premium': false,
      'premium_until': null,
      'is_anonymous': false,
      'credits': {'generic': 29, 'premium_themes': 9},
      'has_voice_pack': true,
    });
    expect(entitlements.credits, {CreditScope.generic: 29, CreditScope.premiumThemes: 9});
    expect(entitlements.canUsePremiumVoices, isTrue);
  });

  testWidgets('packs décrits avec le prix du store, dans l’Espace Parents (US-33)', (tester) async {
    await _openParents(tester, '/parents/packs', entitlements: () => _account);

    expect(find.text('Pack Noël'), findsOneWidget);
    expect(find.text('3,99 €'), findsOneWidget);
    expect(find.textContaining('30 histoires au choix'), findsOneWidget);
    expect(find.text('9,99 €'), findsOneWidget);
  });

  testWidgets('achat d’un pack : crédits ajoutés par le serveur (US-34)', (tester) async {
    final purchases = FakePurchasesRepository();
    await _openParents(
      tester,
      '/parents/packs',
      purchases: purchases,
      entitlements: () => purchases.boughtPacks.isEmpty ? _account : _withCredits({CreditScope.generic: 30}),
    );

    await tester.ensureVisible(find.text('Acheter').at(1));
    await tester.tap(find.text('Acheter').at(1));
    await _settle(tester);

    expect(purchases.boughtPacks, ['pack_famille_30']);
    expect(find.text('Pack Famille : crédits ajoutés.'), findsOneWidget);
    expect(find.text('Vos crédits : Histoires au choix : 30'), findsOneWidget);
  });

  testWidgets('coupure réseau après le paiement : jamais « rien n’a été débité » (US-34)', (tester) async {
    final purchases = FakePurchasesRepository();
    await _openParents(
      tester,
      '/parents/packs',
      purchases: purchases,
      entitlements: () => purchases.boughtPacks.isEmpty ? _account : throw Failure.offline,
    );

    await tester.ensureVisible(find.text('Acheter').at(1));
    await tester.tap(find.text('Acheter').at(1));
    for (var second = 0; second < 11; second++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(purchases.boughtPacks, ['pack_famille_30']);
    expect(find.text('Achat confirmé : ce sera prêt dans un instant.'), findsOneWidget);
    expect(find.textContaining('Rien n’a été débité'), findsNothing);
  });

  testWidgets('Pack Voix : acheté une fois pour toutes (US-37)', (tester) async {
    final purchases = FakePurchasesRepository();
    await _openParents(
      tester,
      '/parents/packs',
      purchases: purchases,
      entitlements: () =>
          Entitlements(freeStoriesLeft: 0, isAnonymous: false, hasVoicePack: purchases.boughtPacks.isNotEmpty),
    );
    expect(find.text('1,99 €'), findsOneWidget);

    await tester.ensureVisible(find.text('Acheter').last);
    await tester.tap(find.text('Acheter').last);
    await _settle(tester);

    expect(purchases.boughtPacks, ['pack_voix']);
    expect(find.text('Pack Voix : voix débloquées.'), findsOneWidget);
    expect(find.text('Déjà acheté'), findsOneWidget);
    expect(find.text('Acheter'), findsNWidgets(2), reason: 'plus de bouton pour le Pack Voix');
  });

  testWidgets('sans compte parent : compte demandé, achat impossible (US-34)', (tester) async {
    final purchases = FakePurchasesRepository();
    await _openParents(tester, '/parents/packs', purchases: purchases);

    expect(find.text('Créer mon compte'), findsOneWidget);
    await tester.ensureVisible(find.text('Acheter').first);
    await tester.tap(find.text('Acheter').first);
    await _settle(tester);
    expect(purchases.boughtPacks, isEmpty);
  });

  testWidgets('store injoignable : packs décrits, sans achat (US-33)', (tester) async {
    await _openParents(
      tester,
      '/parents/packs',
      entitlements: () => _account,
      purchases: FakePurchasesRepository()..isStoreDown = true,
    );

    expect(find.text('Pack Famille'), findsOneWidget);
    expect(find.text('Acheter'), findsNothing);
    expect(find.textContaining('pas disponibles pour le moment'), findsOneWidget);
  });

  testWidgets('solde des crédits dans l’Espace Parents (US-35)', (tester) async {
    await _openParents(
      tester,
      '/parents',
      entitlements: () => _withCredits({CreditScope.generic: 29, CreditScope.noel: 8}),
    );

    expect(find.text('Vos crédits : Histoires au choix : 29 · Noël : 8'), findsOneWidget);
  });

  testWidgets('crédits Aventures : thèmes Premium ouverts, sans crédit ni prix visibles (US-35)', (tester) async {
    await pumpApp(tester, location: '/themes', entitlements: () => _withCredits({CreditScope.premiumThemes: 10}));

    expect(find.bySemanticsLabel('Océan, demande à un parent'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Océan'));
    await _settle(tester);

    expect(find.text('Prépare ton histoire'), findsOneWidget);
    expect(find.textContaining('crédit'), findsNothing);
    expect(find.textContaining('€'), findsNothing);
  });
}

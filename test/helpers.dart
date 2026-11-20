import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/core/router.dart';
import 'package:histoires_du_soir/core/theme/app_theme.dart';
import 'package:histoires_du_soir/features/catalog/data/catalog_repository.dart';
import 'package:histoires_du_soir/features/catalog/domain/story_theme.dart';
import 'package:histoires_du_soir/features/catalog/domain/voice.dart';
import 'package:histoires_du_soir/features/characters/data/characters_repository.dart';
import 'package:histoires_du_soir/features/characters/domain/character.dart';
import 'package:histoires_du_soir/features/offers/data/offers_repository.dart';
import 'package:histoires_du_soir/features/offers/data/purchases_repository.dart';
import 'package:histoires_du_soir/features/offers/domain/credits.dart';
import 'package:histoires_du_soir/features/offers/domain/premium_plan.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';
import 'package:histoires_du_soir/features/session/data/session_repository.dart';
import 'package:histoires_du_soir/features/stories/application/story_providers.dart';
import 'package:histoires_du_soir/features/stories/data/story_repository.dart';
import 'package:histoires_du_soir/features/stories/domain/story.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const testStory = Story(
  id: 'histoire-1',
  themeId: 'animaux',
  durationMin: 2,
  title: 'Le renard et l’étoile',
  paragraphs: ['Il était une fois un petit renard.', 'Bonne nuit, petit renard.'],
);

const testThemes = [
  StoryTheme(id: 'animaux', name: 'Animaux', tier: ThemeTier.free, illustration: 'mascot'),
  StoryTheme(id: 'ocean', name: 'Océan', tier: ThemeTier.premium, illustration: 'castle'),
];

const testVoices = [
  Voice(id: 'douce', name: 'Douce', description: 'Une voix de femme, tendre et posée.'),
  Voice(id: 'lune', name: 'Lune', description: 'Une voix de femme, légère comme un murmure.'),
];

/// Faux serveur d'histoires : chaque création renvoie le résultat suivant de [results] (histoire ou erreur).
class FakeStoryRepository implements StoryRepository {
  FakeStoryRepository([List<Object>? results]) : results = results ?? [testStory];

  final List<Object> results;
  final requests = <StoryRequest>[];

  /// Retient la réponse du serveur tant qu'il n'est pas complété (création en cours).
  Completer<void>? pending;

  @override
  Future<Story> create(StoryRequest request) async {
    requests.add(request);
    await pending?.future;
    final result = results.removeAt(0);
    if (result is Failure) throw result;
    return result as Story;
  }

  @override
  Future<Story?> latest() async => null;

  @override
  Future<Story> byId(String id) async => testStory;

  /// Favoris côté « serveur » ; [favoriteFailure] simule un refus (bibliothèque pleine, réseau).
  final favoriteStories = <Story>[];
  Failure? favoriteFailure;

  /// Temps de réponse du « serveur » pour un favori (double appui pendant l'envoi).
  Duration favoriteDelay = Duration.zero;

  @override
  Future<List<Story>> favorites({required int offset, required int limit}) async =>
      favoriteStories.skip(offset).take(limit).toList();

  @override
  Future<void> setFavorite(String id, {required bool isFavorite}) async {
    await Future<void>.delayed(favoriteDelay);
    if (favoriteFailure != null) throw favoriteFailure!;
    if (isFavorite) {
      favoriteStories.insert(0, testStory);
    } else {
      favoriteStories.removeWhere((story) => story.id == id);
    }
  }

  final reports = <(String, ReportReason, String)>[];

  @override
  Future<void> report(String id, ReportReason reason, String comment) async => reports.add((id, reason, comment));
}

const pipo = Character(
  id: 'pipo',
  name: 'Pipo',
  gender: HeroGender.boy,
  animal: Animal.renard,
  trait: Trait.curieux,
  themeId: 'animaux',
);

const lea = Character(id: 'lea', name: 'Léa', gender: HeroGender.girl, animal: Animal.lapin, trait: Trait.reveur);

/// Faux serveur de personnages : héros prêt à l'emploi [pipo], personnages de la famille en mémoire.
class FakeCharactersRepository implements CharactersRepository {
  FakeCharactersRepository([List<Character> family = const []]) : family = [...family];

  final List<Character> family;
  Failure? saveFailure;

  @override
  Future<List<Character>> characters() async => [...family, pipo];

  @override
  Future<List<Situation>> situations() async => const [(id: 'peur-du-noir', label: 'Peur du noir')];

  @override
  Future<void> save(String? id, CharacterDraft draft) async {
    if (saveFailure != null) throw saveFailure!;
    final character = Character(
      id: id ?? 'perso-${family.length + 1}',
      name: draft.name.trim(),
      gender: draft.gender,
      animal: draft.animal,
      trait: draft.trait,
    );
    final index = family.indexWhere((existing) => existing.id == id);
    index < 0 ? family.add(character) : family[index] = character;
  }

  @override
  Future<void> delete(String id) async => family.removeWhere((character) => character.id == id);
}

const testPlans = [
  PremiumPlan(
    id: r'$rc_annual',
    period: PlanPeriod.annual,
    price: 34.99,
    priceLabel: '34,99 €',
    currencyCode: 'EUR',
    hasFreeTrial: true,
  ),
  PremiumPlan(
    id: r'$rc_monthly',
    period: PlanPeriod.monthly,
    price: 5.99,
    priceLabel: '5,99 €',
    currencyCode: 'EUR',
    hasFreeTrial: true,
  ),
];

const testPacks = [
  CreditPack(
    productId: 'pack_noel_10',
    scope: CreditScope.noel,
    credits: 10,
    name: 'Pack Noël',
    description: '10 histoires de Noël, avec les personnages de votre famille.',
  ),
  CreditPack(
    productId: 'pack_famille_30',
    scope: CreditScope.generic,
    credits: 30,
    name: 'Pack Famille',
    description: '30 histoires au choix : tous les thèmes, toutes les durées, personnages compris.',
  ),
];

/// Faux store : les formules et les packs du lancement, achats enregistrés.
class FakePurchasesRepository implements PurchasesRepository {
  final purchased = <PremiumPlan>[];
  final boughtPacks = <String>[];

  /// Store injoignable pour les packs (pas de prix).
  var isStoreDown = false;

  @override
  Future<Map<String, String>> packPrices(List<String> productIds) async {
    if (isStoreDown) throw Failure.offline;
    return {'pack_noel_10': '3,99 €', 'pack_famille_30': '9,99 €', 'pack_voix': '1,99 €'};
  }

  @override
  Future<bool> buyPack(String productId) async {
    boughtPacks.add(productId);
    return true;
  }

  @override
  Future<List<PremiumPlan>> plans() async => testPlans;

  @override
  Future<bool> purchase(PremiumPlan plan) async {
    purchased.add(plan);
    return true;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<Uri?> managementUrl() async => null;
}

/// L'app complète (routes, thème) sur un téléphone de 390 × 844, sans réseau. Renvoie le conteneur
/// de providers pour inspecter l'état (contrôle parental…).
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  String location = '/',
  int freeStoriesLeft = 3,
  Entitlements Function()? entitlements,
  PurchasesRepository? purchases,
  Story? latestStory,
  StoryRepository? stories,
  CharactersRepository? characters,
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final container = ProviderContainer(
    overrides: [
      themesProvider.overrideWith((ref) async => testThemes),
      voicesProvider.overrideWith((ref) async => testVoices),
      creditPacksProvider.overrideWith((ref) async => testPacks),
      entitlementsProvider.overrideWith(
        (ref) async => entitlements?.call() ?? Entitlements(freeStoriesLeft: freeStoriesLeft),
      ),
      purchasesRepositoryProvider.overrideWithValue(purchases ?? FakePurchasesRepository()),
      latestStoryProvider.overrideWith((ref) async => latestStory),
      storyRepositoryProvider.overrideWithValue(stories ?? FakeStoryRepository()),
      charactersRepositoryProvider.overrideWithValue(characters ?? FakeCharactersRepository()),
      authUserProvider.overrideWith((ref) => Stream.value(null)),
      accountProvider.overrideWithValue((id: 'famille-test', isAnonymous: true)),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final router = buildRouter(
    initialLocation: location,
    isParentUnlocked: () => container.read(parentalGateProvider.notifier).isUnlocked,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: router,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Taille de texte du téléphone (l'app la plafonne à 1,6, comme dans lib/app.dart).
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

/// Résout le défi parental affiché, comme le ferait un adulte.
Future<void> solveParentalGate(WidgetTester tester) async {
  final words = {for (var number = 1; number < 70; number++) frenchNumber(number): number};
  final question = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? '')
      .firstWhere((text) => text.startsWith('Combien font'));
  final match = RegExp('« (.+) plus (.+) »').firstMatch(question)!;
  final answer = words[match.group(1)]! + words[match.group(2)]!;
  for (final digit in '$answer'.split('')) {
    await tester.tap(find.bySemanticsLabel(digit));
    await tester.pump();
  }
  await tester.tap(find.text('Valider'));
  await tester.pump();
  await tester.pump();
}

/// Navigue comme un lien interne de l'app.
Future<void> goTo(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).last)).go(location);
  for (var frame = 0; frame < 3; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

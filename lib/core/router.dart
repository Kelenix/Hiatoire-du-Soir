import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/presentation/themes_screen.dart';
import '../features/characters/domain/character.dart';
import '../features/characters/presentation/characters_screen.dart';
import '../features/offers/presentation/ask_parent_screen.dart';
import '../features/offers/presentation/packs_screen.dart';
import '../features/offers/presentation/premium_screen.dart';
import '../features/parental_gate/application/parental_gate.dart';
import '../features/parental_gate/presentation/parental_gate_screen.dart';
import '../features/parents/presentation/account_screen.dart';
import '../features/parents/presentation/family_characters_screen.dart';
import '../features/parents/presentation/parents_home_screen.dart';
import '../features/parents/presentation/report_screen.dart';
import '../features/parents/presentation/settings_screen.dart';
import '../features/parents/presentation/support_screen.dart';
import '../features/stories/presentation/child_home_screen.dart';
import '../features/stories/presentation/creating_screen.dart';
import '../features/stories/domain/story.dart';
import '../features/stories/presentation/my_stories_screen.dart';
import '../features/stories/presentation/story_options_screen.dart';
import '../features/stories/presentation/story_screen.dart';

/// Toutes les routes sont imbriquées sous l'accueil : « retour » y ramène toujours.
/// L'Espace Parents (`/parents…`) exige un contrôle parental récent (US-16).
GoRouter buildRouter({required bool Function() isParentUnlocked, String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) {
    if (!state.uri.path.startsWith('/parents') || isParentUnlocked()) return null;
    return Uri(path: '/controle-parental', queryParameters: {'suite': state.uri.toString()}).toString();
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ChildHomeScreen(),
      routes: [
        GoRoute(
          path: 'themes',
          builder: (context, state) => ThemesScreen(heroId: state.uri.queryParameters['heros']),
        ),
        GoRoute(
          path: 'preparer/:themeId',
          builder: (context, state) =>
              StoryOptionsScreen(themeId: state.pathParameters['themeId']!, heroId: state.uri.queryParameters['heros']),
        ),
        GoRoute(
          path: 'creer/:themeId',
          builder: (context, state) => CreatingScreen(
            themeId: state.pathParameters['themeId']!,
            options: state.extra as StoryOptions? ?? defaultStoryOptions,
          ),
        ),
        GoRoute(path: 'personnages', builder: (context, state) => const CharactersScreen()),
        GoRoute(
          path: 'histoire/:id',
          builder: (context, state) => StoryScreen(storyId: state.pathParameters['id']!),
        ),
        GoRoute(path: 'mes-histoires', builder: (context, state) => const MyStoriesScreen()),
        GoRoute(path: 'demande-parent', builder: (context, state) => const AskParentScreen()),
        GoRoute(
          path: 'controle-parental',
          builder: (context, state) => ParentalGateScreen(next: state.uri.queryParameters['suite'] ?? '/parents'),
        ),
        GoRoute(
          path: 'parents',
          builder: (context, state) => const ParentsHomeScreen(),
          routes: [
            GoRoute(path: 'premium', builder: (context, state) => const PremiumScreen()),
            GoRoute(path: 'packs', builder: (context, state) => const PacksScreen()),
            GoRoute(path: 'compte', builder: (context, state) => const AccountScreen()),
            GoRoute(
              path: 'personnages',
              builder: (context, state) => const FamilyCharactersScreen(),
              routes: [
                GoRoute(
                  path: 'edition',
                  builder: (context, state) => CharacterFormScreen(character: state.extra as Character?),
                ),
              ],
            ),
            GoRoute(path: 'parametres', builder: (context, state) => const SettingsScreen()),
            GoRoute(path: 'support', builder: (context, state) => const SupportScreen()),
            GoRoute(
              path: 'signaler/:id',
              builder: (context, state) => ReportScreen(storyId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
  ],
);

final routerProvider = Provider(
  (ref) => buildRouter(isParentUnlocked: () => ref.read(parentalGateProvider.notifier).isUnlocked),
);

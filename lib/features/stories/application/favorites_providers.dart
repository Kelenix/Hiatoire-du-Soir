import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure.dart';
import '../../session/data/session_repository.dart';
import '../data/story_repository.dart';
import '../domain/story.dart';
import 'story_providers.dart';

/// Cœur d'une histoire (US-13, US-14). Le serveur fait foi : l'état ne change qu'après sa réponse.
class FavoriteController extends AutoDisposeFamilyNotifier<bool, Story> {
  var _isSaving = false;

  @override
  bool build(Story story) => story.isFavorite;

  /// Renvoie l'échec éventuel, que l'écran explique (bibliothèque pleine, réseau…). Un second appui
  /// pendant l'envoi est ignoré.
  Future<Failure?> toggle() async {
    if (_isSaving) return null;
    _isSaving = true;
    final target = !state;
    try {
      await ref.read(storyRepositoryProvider).setFavorite(arg.id, isFavorite: target);
      state = target;
      ref
        ..invalidate(favoritesProvider)
        ..invalidate(latestStoryProvider);
      return null;
    } on Failure catch (failure) {
      return failure;
    } finally {
      _isSaving = false;
    }
  }
}

final favoriteProvider = NotifierProvider.autoDispose.family<FavoriteController, bool, Story>(FavoriteController.new);

typedef FavoriteStories = ({List<Story> stories, bool hasMore});

/// « Mes histoires » : favoris chargés par pages de 20 (US-15).
class FavoritesController extends AsyncNotifier<FavoriteStories> {
  static const pageSize = 20;

  @override
  Future<FavoriteStories> build() {
    ref.watch(accountProvider.select((account) => account.id));
    return _next(const []);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    state = await AsyncValue.guard(() => _next(current.stories));
  }

  Future<FavoriteStories> _next(List<Story> loaded) async {
    final page = await ref.read(storyRepositoryProvider).favorites(offset: loaded.length, limit: pageSize);
    return (stories: [...loaded, ...page], hasMore: page.length == pageSize);
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesController, FavoriteStories>(FavoritesController.new);

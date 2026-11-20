import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failure.dart';
import '../domain/story.dart';

/// Une demande de création ; son `requestId` la rend rejouable sans double débit.
typedef StoryRequest = ({String requestId, String themeId, StoryOptions options});

class StoryRepository {
  const StoryRepository(this._db);

  final SupabaseClient _db;

  /// Demande une histoire au serveur, qui vérifie les droits de chaque option (US-32).
  Future<Story> create(StoryRequest request) => guard(() async {
    final options = request.options;
    final response = await _db.functions
        .invoke(
          'generate-story',
          body: {
            'request_id': request.requestId,
            'theme_id': request.themeId,
            'duration_min': options.durationMin,
            'character_id': ?options.characterId,
            'animal': ?options.animal?.name,
            'situation_id': ?options.situationId,
            'situation_text': ?options.situationText,
          },
        )
        .timeout(Duration(seconds: 50 + 10 * options.durationMin));
    return Story.fromJson((response.data as Map<String, dynamic>)['story'] as Map<String, dynamic>);
  });

  /// Dernière histoire créée (H13), s'il y en a une.
  Future<Story?> latest() => guard(() async {
    final row = await _db.from('stories').select().order('created_at', ascending: false).limit(1).maybeSingle();
    return row == null ? null : Story.fromJson(row);
  });

  Future<Story> byId(String id) =>
      guard(() async => Story.fromJson(await _db.from('stories').select().eq('id', id).single()));

  /// Favoris, du plus récent au plus ancien, par pages (US-15).
  Future<List<Story>> favorites({required int offset, required int limit}) => guard(() async {
    final rows = await _db
        .from('stories')
        .select()
        .eq('is_favorite', true)
        .order('favorited_at', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map(Story.fromJson).toList();
  });

  /// Ajoute ou retire un favori ; le serveur refuse le 4ᵉ en gratuit ([Failure.favoritesLimit]).
  Future<void> setFavorite(String id, {required bool isFavorite}) =>
      guard(() => _db.rpc<void>('set_favorite', params: {'p_story_id': id, 'p_value': isFavorite}));

  /// Signale une histoire : copiée sans prénom pour analyse, puis retirée de l'app (US-22).
  Future<void> report(String id, ReportReason reason, String comment) => guard(
    () => _db.rpc<void>('report_story', params: {'p_story_id': id, 'p_reason': reason.name, 'p_comment': comment}),
  );
}

enum ReportReason {
  scary('Elle fait peur'),
  violent('Elle est violente'),
  inappropriate('Elle ne convient pas à un enfant'),
  quality('Elle est mal écrite ou incohérente'),
  other('Autre raison');

  const ReportReason(this.label);

  final String label;
}

final storyRepositoryProvider = Provider((ref) => StoryRepository(Supabase.instance.client));

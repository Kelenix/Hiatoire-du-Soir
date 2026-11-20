import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failure.dart';
import '../domain/story_theme.dart';
import '../domain/voice.dart';

class CatalogRepository {
  const CatalogRepository(this._db);

  final SupabaseClient _db;

  /// Thèmes actifs, dans l'ordre du catalogue (la RLS masque les inactifs).
  Future<List<StoryTheme>> themes() => guard(() async {
    final rows = await _db.from('themes').select('id, name, tier, illustration').order('sort_order', ascending: true);
    return rows.map(StoryTheme.fromJson).toList();
  });

  /// Voix apaisantes actives, dans l'ordre du catalogue.
  Future<List<Voice>> voices() => guard(() async {
    final rows = await _db.from('voices').select('id, name, description').order('sort_order', ascending: true);
    return rows.map(Voice.fromJson).toList();
  });
}

final catalogRepositoryProvider = Provider((ref) => CatalogRepository(Supabase.instance.client));

final themesProvider = FutureProvider((ref) => ref.watch(catalogRepositoryProvider).themes());

final voicesProvider = FutureProvider((ref) => ref.watch(catalogRepositoryProvider).voices());

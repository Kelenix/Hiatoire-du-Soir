import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failure.dart';
import '../../session/data/session_repository.dart';
import '../domain/character.dart';

class CharactersRepository {
  const CharactersRepository(this._db);

  final SupabaseClient _db;

  /// Personnages de la famille, puis héros prêts à l'emploi (la RLS masque ceux des autres familles).
  Future<List<Character>> characters() => guard(() async {
    final rows = await _db
        .from('characters')
        .select('id, name, gender, animal, trait, theme_id')
        .order('created_at', ascending: true)
        .order('name', ascending: true);
    final characters = rows.map(Character.fromJson).toList();
    return [...characters.where((character) => character.isFamily), ...characters.where((c) => !c.isFamily)];
  });

  Future<List<Situation>> situations() => guard(() async {
    final rows = await _db.from('situations').select('id, label').order('sort_order', ascending: true);
    return [for (final row in rows) (id: row['id'] as String, label: row['label'] as String)];
  });

  /// Crée ([id] absent) ou modifie un personnage ; le 11ᵉ est refusé ([Failure.charactersLimit]).
  Future<void> save(String? id, CharacterDraft draft) => guard(() async {
    final values = {
      'name': draft.name.trim(),
      'gender': draft.gender.name,
      'animal': draft.animal.name,
      'trait': draft.trait.name,
    };
    if (id == null) {
      await _db.from('characters').insert({...values, 'user_id': _db.auth.currentUser!.id});
    } else {
      await _db.from('characters').update(values).eq('id', id);
    }
  });

  /// Les histoires déjà créées gardent leur héros.
  Future<void> delete(String id) => guard(() => _db.from('characters').delete().eq('id', id));
}

final charactersRepositoryProvider = Provider((ref) => CharactersRepository(Supabase.instance.client));

final charactersProvider = FutureProvider((ref) {
  ref.watch(accountProvider.select((account) => account.id));
  return ref.watch(charactersRepositoryProvider).characters();
});

final situationsProvider = FutureProvider((ref) => ref.watch(charactersRepositoryProvider).situations());

/// Modifications du parent (P5) : la liste n'est rafraîchie qu'après la réponse du serveur.
class CharacterEditor {
  const CharacterEditor(this._ref);

  final Ref _ref;

  /// Renvoie l'échec éventuel, que l'écran explique (limite atteinte, réseau…).
  Future<Failure?> save(String? id, CharacterDraft draft) =>
      _run(() => _ref.read(charactersRepositoryProvider).save(id, draft));

  Future<Failure?> delete(String id) => _run(() => _ref.read(charactersRepositoryProvider).delete(id));

  Future<Failure?> _run(Future<void> Function() change) async {
    try {
      await change();
      _ref.invalidate(charactersProvider);
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }
}

final characterEditorProvider = Provider(CharacterEditor.new);

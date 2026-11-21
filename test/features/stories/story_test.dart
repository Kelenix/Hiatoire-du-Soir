import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/features/stories/application/story_providers.dart';
import 'package:histoires_du_soir/features/stories/domain/story.dart';

void main() {
  test('lit une histoire telle que renvoyée par le serveur', () {
    final story = Story.fromJson({
      'id': '7d1c2b8e-5d1f-4a43-9a8e-2f3b6c1d9e10',
      'user_id': '00000000-0000-0000-0000-00000000000a',
      'theme_id': 'animaux',
      'duration_min': 2,
      'title': 'Le renard et l’étoile',
      'paragraphs': ['Il était une fois…', 'Bonne nuit.'],
      'listens_count': 1,
      'is_favorite': true,
      'favorited_at': '2026-11-20T20:05:00+00:00',
      'created_at': '2026-11-20T20:00:00+00:00',
    });

    expect(story.title, 'Le renard et l’étoile');
    expect(story.paragraphs, hasLength(2));
    expect(story.durationMin, 2);
    expect(story.listensCount, 1);
    expect(story.isFavorite, isTrue);
  });

  test('le prénom, gardé à part par le serveur, est remis dans le texte avec l’élision (US-32)', () {
    Story named(String? heroName) => Story.fromJson({
      'id': 'histoire-2',
      'theme_id': 'animaux',
      'duration_min': 2,
      'title': 'La nuit de {{HEROS}}',
      'paragraphs': ['{{HEROS}} sourit. Lorsque {{HEROS}} dort, la lune veille sur elle.'],
      'listens_count': 0,
      'is_favorite': false,
      'hero_name': heroName,
    });

    expect(named('Emma').title, 'La nuit d’Emma');
    expect(named('Emma').paragraphs.single, 'Emma sourit. Lorsqu’Emma dort, la lune veille sur elle.');
    expect(named('Léa').title, 'La nuit de Léa');
    expect(withHeroName('Une idée de {{HEROS}}', null), 'Une idée de {{HEROS}}');
  });

  test('chaque demande de création a un identifiant UUID v4 unique', () {
    final uuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final ids = List.generate(50, (_) => newRequestId());

    expect(ids.every(uuidV4.hasMatch), isTrue);
    expect(ids.toSet(), hasLength(50));
  });
}

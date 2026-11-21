import '../../characters/domain/character.dart';

class Story {
  const Story({
    required this.id,
    required this.themeId,
    required this.durationMin,
    required this.title,
    required this.paragraphs,
    this.listensCount = 0,
    this.isFavorite = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final heroName = json['hero_name'] as String?;
    String named(String text) => withHeroName(text, heroName);
    return Story(
      id: json['id'] as String,
      themeId: json['theme_id'] as String,
      durationMin: json['duration_min'] as int,
      title: named(json['title'] as String),
      paragraphs: (json['paragraphs'] as List<dynamic>).cast<String>().map(named).toList(),
      listensCount: json['listens_count'] as int,
      isFavorite: json['is_favorite'] as bool,
    );
  }

  final String id;
  final String themeId;
  final int durationMin;
  final String title;
  final List<String> paragraphs;
  final int listensCount;
  final bool isFavorite;
}

/// Le texte stocké ne contient jamais le prénom, seulement ce marqueur (ADR-017).
const heroMarker = '{{HEROS}}';

final _elision = RegExp(r'(?<!\p{L})(d|D|qu|Qu|lorsqu|Lorsqu|puisqu|Puisqu)e \{\{HEROS\}\}', unicode: true);
final _startsWithVowel = RegExp('^[aeiouyàâéèêëîïôûù]', caseSensitive: false);

/// Remet le prénom dans le texte, avec l'élision (« d’Emma », « qu’Emma »).
String withHeroName(String text, String? name) {
  if (name == null) return text;
  final elided = _startsWithVowel.hasMatch(name)
      ? text.replaceAllMapped(_elision, (match) => '${match[1]}’$name')
      : text;
  return elided.replaceAll(heroMarker, name);
}

/// Choix faits avant la création (maquette E3). Sans option : 2 minutes, héros inventé par l'histoire.
typedef StoryOptions = ({
  int durationMin,
  String? characterId,
  Animal? animal,
  String? situationId,
  String? situationText,
});

const StoryOptions defaultStoryOptions = (
  durationMin: 2,
  characterId: null,
  animal: null,
  situationId: null,
  situationText: null,
);

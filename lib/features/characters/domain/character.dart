// Personnages et situations (US-30 à US-32). Listes fermées, identiques à la table characters et à
// generate-story : ajouter une valeur demande une migration.

enum HeroGender {
  girl('Fille'),
  boy('Garçon'),
  neutral('Neutre');

  const HeroGender(this.label);

  final String label;
}

enum Animal {
  renard('🦊', 'Renard'),
  lapin('🐰', 'Lapin'),
  ours('🐻', 'Ours'),
  chat('🐱', 'Chat'),
  chien('🐶', 'Chien'),
  chouette('🦉', 'Chouette'),
  dragon('🐉', 'Dragon'),
  licorne('🦄', 'Licorne'),
  dauphin('🐬', 'Dauphin'),
  tortue('🐢', 'Tortue');

  const Animal(this.emoji, this.label);

  final String emoji;
  final String label;
}

/// Libellés en noms (« Courage ») : ils conviennent aux filles comme aux garçons.
enum Trait {
  courageux('🦁', 'Courage'),
  curieux('🔍', 'Curiosité'),
  rigolo('😄', 'Humour'),
  doux('🧸', 'Douceur'),
  malin('💡', 'Malice'),
  reveur('☁️', 'Rêverie');

  const Trait(this.emoji, this.label);

  final String emoji;
  final String label;
}

/// Ce que le parent saisit (P5).
typedef CharacterDraft = ({String name, HeroGender gender, Animal animal, Trait trait});

/// Héros prêt à l'emploi (lié à un thème) ou personnage de la famille.
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.gender,
    required this.animal,
    required this.trait,
    this.themeId,
  });

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as String,
    name: json['name'] as String,
    gender: HeroGender.values.byName(json['gender'] as String),
    animal: Animal.values.byName(json['animal'] as String),
    trait: Trait.values.byName(json['trait'] as String),
    themeId: json['theme_id'] as String?,
  );

  final String id;
  final String name;
  final HeroGender gender;
  final Animal animal;
  final Trait trait;
  final String? themeId;

  /// Créé par le parent : son usage relève de l'offre sur mesure (Premium ou crédit).
  bool get isFamily => themeId == null;

  CharacterDraft get draft => (name: name, gender: gender, animal: animal, trait: trait);
}

typedef Situation = ({String id, String label});

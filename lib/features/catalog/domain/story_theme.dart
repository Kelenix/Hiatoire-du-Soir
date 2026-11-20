enum ThemeTier { free, premium, seasonal }

class StoryTheme {
  const StoryTheme({required this.id, required this.name, required this.tier, required this.illustration});

  factory StoryTheme.fromJson(Map<String, dynamic> json) => StoryTheme(
    id: json['id'] as String,
    name: json['name'] as String,
    tier: ThemeTier.values.byName(json['tier'] as String),
    illustration: json['illustration'] as String,
  );

  final String id;
  final String name;
  final ThemeTier tier;
  final String illustration;

  /// Accessible dans l'offre gratuite ; les droits Premium et les crédits arrivent aux Inc-5 et Inc-7.
  bool get isFree => tier == ThemeTier.free;
}

/// Voix apaisante (US-36), synthétisée par le serveur ; réservée au Premium et au Pack Voix.
class Voice {
  const Voice({required this.id, required this.name, required this.description});

  factory Voice.fromJson(Map<String, dynamic> json) =>
      Voice(id: json['id'] as String, name: json['name'] as String, description: json['description'] as String);

  final String id;
  final String name;
  final String description;
}

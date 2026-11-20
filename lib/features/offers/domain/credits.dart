/// Portées des crédits (H16), identiques à `credit_scope` en base.
enum CreditScope {
  generic('generic', 'Histoires au choix'),
  premiumThemes('premium_themes', 'Aventures Premium'),
  noel('noel', 'Noël'),
  custom('custom', 'Histoires sur mesure');

  const CreditScope(this.dbName, this.label);

  final String dbName;
  final String label;

  static CreditScope fromDb(String value) => values.firstWhere((scope) => scope.dbName == value);
}

/// Pack vendu par les stores : contenu en base, prix fourni par le store (US-33).
class CreditPack {
  const CreditPack({
    required this.productId,
    required this.scope,
    required this.credits,
    required this.name,
    required this.description,
  });

  factory CreditPack.fromJson(Map<String, dynamic> json) => CreditPack(
    productId: json['product_id'] as String,
    scope: CreditScope.fromDb(json['scope'] as String),
    credits: json['credits'] as int,
    name: json['name'] as String,
    description: json['description'] as String,
  );

  final String productId;
  final CreditScope scope;
  final int credits;
  final String name;
  final String description;
}

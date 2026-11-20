import 'package:intl/intl.dart';

enum PlanPeriod { annual, monthly }

/// Formule Premium telle que vendue par le store (prix dans la devise du parent, US-24).
class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.period,
    required this.price,
    required this.priceLabel,
    required this.currencyCode,
    required this.hasFreeTrial,
  });

  final String id;
  final PlanPeriod period;
  final double price;
  final String priceLabel;
  final String currencyCode;
  final bool hasFreeTrial;

  String get monthlyEquivalent => NumberFormat.simpleCurrency(locale: 'fr', name: currencyCode).format(price / 12);
}

/// Économie de l'annuel par rapport à 12 mois au tarif mensuel, en pourcentage arrondi.
int annualSavingsPercent({required PremiumPlan annual, required PremiumPlan monthly}) =>
    ((1 - annual.price / (12 * monthly.price)) * 100).round();

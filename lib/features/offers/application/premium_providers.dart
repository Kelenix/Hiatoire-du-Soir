import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure.dart';
import '../data/offers_repository.dart';
import '../data/purchases_repository.dart';
import '../domain/credits.dart';
import '../domain/premium_plan.dart';

final premiumPlansProvider = FutureProvider.autoDispose((ref) => ref.watch(purchasesRepositoryProvider).plans());

// Les achats reçoivent le conteneur de providers, pas la `ref` d'un écran : le paiement peut faire
// passer l'app en arrière-plan (validation bancaire), ce qui referme l'Espace Parents (H22).

/// Achète la formule puis attend que le webhook ait ouvert les droits côté serveur (≤ 10 s, US-25).
/// Renvoie `false` si le parent a annulé.
Future<bool> subscribe(ProviderContainer container, PremiumPlan plan) async {
  if (!await container.read(purchasesRepositoryProvider).purchase(plan)) return false;
  await _waitFor(container, (entitlements) => entitlements.isPremium);
  return true;
}

/// Restaure un abonnement ou un Pack Voix déjà payés (US-26) ; `false` s'il n'y avait rien à restaurer.
Future<bool> restorePurchases(ProviderContainer container) async {
  await container.read(purchasesRepositoryProvider).restore();
  return _waitFor(container, (entitlements) => entitlements.isPremium || entitlements.hasVoicePack);
}

/// Pack Voix (US-37) : achat définitif, hors catalogue des crédits.
const voicePackId = 'pack_voix';

typedef PackOffers = ({List<CreditPack> packs, Map<String, String> prices});

/// Packs et prix du store ; sans store joignable, les packs restent décrits mais sans prix.
final packOffersProvider = FutureProvider.autoDispose<PackOffers>((ref) async {
  final packs = await ref.watch(creditPacksProvider.future);
  final prices = await ref
      .watch(purchasesRepositoryProvider)
      .packPrices([for (final pack in packs) pack.productId, voicePackId])
      .catchError((Object _) => const <String, String>{});
  return (packs: packs, prices: prices);
});

enum PackPurchase { cancelled, delivered, pending }

/// Achète un pack puis attend que le webhook ait ajouté ses crédits (≤ 10 s, US-34).
Future<PackPurchase> buyPack(ProviderContainer container, CreditPack pack) {
  int balance(Entitlements? entitlements) => entitlements?.credits[pack.scope] ?? 0;
  final before = balance(container.read(entitlementsProvider).valueOrNull);
  return _buyProduct(container, pack.productId, (entitlements) => balance(entitlements) > before);
}

/// Achète le Pack Voix puis attend que le webhook l'ait enregistré (≤ 10 s, US-37).
Future<PackPurchase> buyVoicePack(ProviderContainer container) =>
    _buyProduct(container, voicePackId, (entitlements) => entitlements.hasVoicePack);

Future<PackPurchase> _buyProduct(
  ProviderContainer container,
  String productId,
  bool Function(Entitlements) isDelivered,
) async {
  if (!await container.read(purchasesRepositoryProvider).buyPack(productId)) return PackPurchase.cancelled;
  return await _waitFor(container, isDelivered) ? PackPurchase.delivered : PackPurchase.pending;
}

/// Le paiement est fait : une coupure pendant l'attente ne doit jamais faire croire à un échec.
Future<bool> _waitFor(ProviderContainer container, bool Function(Entitlements entitlements) isDone) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      if (isDone(await container.refresh(entitlementsProvider.future))) return true;
    } on Failure {
      // Nouvel essai à la seconde suivante.
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  return false;
}

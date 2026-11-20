import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../application/premium_providers.dart';
import '../data/offers_repository.dart';
import '../domain/credits.dart';
import 'account_first.dart';

/// Packs d'histoires et Pack Voix (US-33, US-34, US-37), dans l'Espace Parents, pour les parents non
/// abonnés (ADR-011).
class PacksScreen extends ConsumerStatefulWidget {
  const PacksScreen({super.key});

  @override
  ConsumerState<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends ConsumerState<PacksScreen> {
  var _isBusy = false;

  /// [delivered] : ce qui est prêt une fois l'achat enregistré par le serveur (« crédits ajoutés »).
  Future<void> _buy(
    String name,
    String delivered,
    Future<PackPurchase> Function(ProviderContainer container) purchase,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _isBusy = true);
    try {
      final message = switch (await purchase(container)) {
        PackPurchase.delivered => '$name : $delivered.',
        PackPurchase.pending => 'Achat confirmé : ce sera prêt dans un instant.',
        PackPurchase.cancelled => null,
      };
      if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
    } on Failure catch (failure) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failure == Failure.offline
                ? 'Pas de connexion Internet. Réessayez dans un instant.'
                : 'L’achat n’a pas abouti. Rien n’a été débité.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    final textTheme = Theme.of(context).textTheme;
    final isAnonymous = entitlements?.isAnonymous ?? true;
    final canBuy = !_isBusy && !isAnonymous;
    return NightScaffold(
      title: 'Packs d’histoires et de voix',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Des histoires en plus, sans abonnement. Les crédits n’expirent pas.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          if (entitlements != null && entitlements.credits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Vos crédits : ${creditsSummary(entitlements.credits)}',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium!.copyWith(color: AppColors.gold),
            ),
          ],
          const SizedBox(height: 20),
          if (isAnonymous) ...[
            const AccountFirst(
              message: 'Pour garder vos crédits sur tous vos appareils, créez d’abord votre compte parent.',
            ),
            const SizedBox(height: 20),
          ],
          ...ref
              .watch(packOffersProvider)
              .when(
                data: (offers) => [
                  if (offers.prices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Les achats ne sont pas disponibles pour le moment. Réessayez un peu plus tard.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  for (final pack in offers.packs)
                    _PackCard(
                      name: pack.name,
                      description: pack.description,
                      price: offers.prices[pack.productId],
                      onBuy: canBuy
                          ? () => _buy(pack.name, 'crédits ajoutés', (container) => buyPack(container, pack))
                          : null,
                    ),
                  _PackCard(
                    name: 'Pack Voix',
                    description: 'Les voix apaisantes pour écouter les histoires, achetées une fois pour toutes.',
                    price: offers.prices[voicePackId],
                    isOwned: entitlements?.hasVoicePack ?? false,
                    onBuy: canBuy ? () => _buy('Pack Voix', 'voix débloquées', buyVoicePack) : null,
                  ),
                ],
                loading: () => [const Center(child: CircularProgressIndicator())],
                error: (_, _) => [
                  Text(
                    'Les packs ne sont pas disponibles pour le moment. Réessayez un peu plus tard.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
        ],
      ),
    );
  }
}

/// « Histoires au choix : 29 · Noël : 8 ».
String creditsSummary(Map<CreditScope, int> credits) =>
    [for (final MapEntry(:key, :value) in credits.entries) '${key.label} : $value'].join(' · ');

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.name,
    required this.description,
    required this.price,
    required this.onBuy,
    this.isOwned = false,
  });

  final String name;
  final String description;
  final String? price;
  final VoidCallback? onBuy;

  /// Achat définitif déjà fait (Pack Voix) : plus de bouton d'achat.
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: textTheme.titleMedium)),
                  if (isOwned)
                    Text('Déjà acheté', style: textTheme.titleMedium!.copyWith(color: AppColors.gold))
                  else if (price != null)
                    Text(price!, style: textTheme.titleMedium!.copyWith(color: AppColors.gold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(description, style: textTheme.bodySmall),
              if (price != null && !isOwned) ...[
                const SizedBox(height: 12),
                OutlinePillButton(label: 'Acheter', onPressed: onBuy),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

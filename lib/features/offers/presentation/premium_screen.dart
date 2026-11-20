import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_images.dart';
import '../../../core/config.dart';
import '../../../core/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../parents/presentation/external_link.dart';
import '../application/premium_providers.dart';
import '../data/offers_repository.dart';
import '../domain/premium_plan.dart';
import 'account_first.dart';

/// Offre Premium (US-24 à US-26, maquette P2), dans l'Espace Parents uniquement.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  static const _benefits = [
    'Histoires illimitées',
    'Tous les thèmes, dont Noël et Halloween',
    'Histoires de 2, 5 ou 10 minutes',
    'Écoutes et favoris illimités',
    'Voix apaisantes et histoires sur mesure',
  ];

  var _selected = PlanPeriod.annual;
  var _isBusy = false;

  /// [action] renvoie le message à montrer, ou rien si le parent a annulé.
  Future<void> _run(Future<String?> Function(ProviderContainer container) action) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _isBusy = true);
    try {
      final message = await action(container);
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
        router.go('/parents');
      }
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
    return NightScaffold(
      title: 'Premium',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Image.asset(AppImages.iconCrown, height: 96, excludeFromSemantics: true),
          const SizedBox(height: 12),
          Text(
            'Créez des histoires illimitées pour votre enfant.',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          for (final benefit in _benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(child: Text(benefit, style: textTheme.bodyLarge)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (entitlements?.isAnonymous ?? true)
            const AccountFirst(
              message: 'Pour garder votre abonnement sur tous vos appareils, créez d’abord votre compte parent.',
            )
          else
            _plans(),
          TextButton(
            onPressed: () => context.push('/parents/packs'),
            child: const Text('Sans abonnement : voir les packs d’histoires'),
          ),
          if (AppConfig.legalUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => openExternal(context, ref, Uri.parse(AppConfig.legalUrl)),
              child: const Text('Conditions de vente et confidentialité'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _plans() {
    return ref
        .watch(premiumPlansProvider)
        .when(
          data: (plans) {
            final annual = plans.where((plan) => plan.period == PlanPeriod.annual).firstOrNull;
            final monthly = plans.where((plan) => plan.period == PlanPeriod.monthly).firstOrNull;
            final selected = plans.where((plan) => plan.period == _selected).firstOrNull ?? plans.firstOrNull;
            if (selected == null) return const _Unavailable();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (annual != null)
                  _PlanCard(
                    title: 'Annuel',
                    price: '${annual.priceLabel} / an',
                    detail: [
                      'soit ${annual.monthlyEquivalent} / mois',
                      if (monthly != null) '−${annualSavingsPercent(annual: annual, monthly: monthly)} %',
                    ].join('  ·  '),
                    isSelected: selected == annual,
                    onTap: () => setState(() => _selected = PlanPeriod.annual),
                  ),
                if (monthly != null)
                  _PlanCard(
                    title: 'Mensuel',
                    price: '${monthly.priceLabel} / mois',
                    isSelected: selected == monthly,
                    onTap: () => setState(() => _selected = PlanPeriod.monthly),
                  ),
                const SizedBox(height: 16),
                MagicButton(
                  label: selected.hasFreeTrial ? 'Essayer 7 jours gratuits' : 'S’abonner',
                  onPressed: _isBusy
                      ? null
                      : () => _run(
                          (container) async => await subscribe(container, selected) ? 'Bienvenue dans Premium !' : null,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Renouvellement automatique, résiliable à tout moment depuis le store.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => _run(
                          (container) async => await restorePurchases(container)
                              ? 'Achats restaurés.'
                              : 'Aucun achat à restaurer pour ce compte du store.',
                        ),
                  child: const Text('Restaurer mes achats'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _Unavailable(),
        );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.isSelected,
    required this.onTap,
    this.detail,
  });

  final String title;
  final String price;
  final String? detail;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: isSelected,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.lavender : AppColors.cardBorder,
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: AppColors.lavender,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleMedium),
                        if (detail != null) Text(detail!, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(price, style: textTheme.titleMedium!.copyWith(color: AppColors.gold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => Text(
    'Les offres ne sont pas disponibles pour le moment. Réessayez un peu plus tard.',
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodyLarge,
  );
}

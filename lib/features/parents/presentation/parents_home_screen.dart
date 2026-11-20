import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/app_images.dart';
import '../../../core/config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/data/purchases_repository.dart';
import '../../offers/presentation/packs_screen.dart';
import '../../session/data/session_repository.dart';
import 'external_link.dart';

/// Accueil de l'Espace Parents (US-17, maquette P1).
class ParentsHomeScreen extends ConsumerWidget {
  const ParentsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    final user = ref.watch(authUserProvider).valueOrNull;
    final email = user == null || user.isAnonymous ? null : user.email;
    return NightScaffold(
      title: 'Espace Parents',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (entitlements?.isPremium ?? false)
            _Section(
              image: AppImages.iconCrown,
              title: 'Premium',
              subtitle: entitlements!.premiumUntil == null
                  ? 'Gérer ou résilier l’abonnement.'
                  : 'Actif jusqu’au ${DateFormat.yMMMMd('fr').format(entitlements.premiumUntil!)}. '
                        'Gérer ou résilier l’abonnement.',
              onTap: () => _manageSubscription(context, ref),
            )
          else ...[
            _Section(
              image: AppImages.iconCrown,
              title: 'Offre gratuite',
              subtitle: entitlements == null
                  ? 'Histoires de 2 minutes, thèmes Animaux et Forêt magique.'
                  : '${_freeStoriesText(entitlements.freeStoriesLeft)} cette semaine '
                        '(3 par semaine, remise à zéro le lundi).',
            ),
            OutlinePillButton(
              label: 'Passer Premium',
              icon: Icons.workspace_premium_rounded,
              onPressed: () => context.push('/parents/premium'),
            ),
            const SizedBox(height: 12),
            _Section(
              image: AppImages.iconBook,
              title: 'Packs d’histoires et de voix',
              subtitle: entitlements == null || entitlements.credits.isEmpty
                  ? 'Des histoires en plus, sans abonnement.'
                  : 'Vos crédits : ${creditsSummary(entitlements.credits)}',
              onTap: () => context.push('/parents/packs'),
            ),
          ],
          _Section(
            image: AppImages.mascot,
            title: 'Personnages',
            subtitle: 'Le personnage de votre enfant, héros des histoires.',
            onTap: () => context.push('/parents/personnages'),
          ),
          _Section(
            image: AppImages.iconFamily,
            title: 'Compte',
            subtitle: email ?? 'Créez un compte pour retrouver vos histoires sur un autre appareil.',
            onTap: () => context.push('/parents/compte'),
          ),
          _Section(
            image: AppImages.iconPlay,
            title: 'Réglages de lecture',
            subtitle: 'Voix, vitesse de lecture, taille du texte.',
            onTap: () => context.push('/parents/parametres'),
          ),
          _Section(
            image: AppImages.iconBook,
            title: 'Aide et support',
            subtitle: 'Questions fréquentes, nous écrire.',
            onTap: () => context.push('/parents/support'),
          ),
          if (AppConfig.legalUrl.isNotEmpty)
            _Section(
              image: AppImages.iconBook,
              title: 'Informations légales',
              subtitle: 'Confidentialité, conditions d’utilisation et de vente, mentions légales.',
              onTap: () => openExternal(context, ref, Uri.parse(AppConfig.legalUrl)),
            ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => context.go('/'), child: const Text('Retour à l’Espace Enfant')),
        ],
      ),
    );
  }
}

String _freeStoriesText(int count) =>
    count > 1 ? 'Encore $count histoires gratuites' : 'Encore $count histoire gratuite';

/// Page du store où l'abonnement se gère et se résilie (US-26).
Future<void> _manageSubscription(BuildContext context, WidgetRef ref) async {
  final storePage = Platform.isIOS
      ? Uri.parse('https://apps.apple.com/account/subscriptions')
      : Uri.parse('https://play.google.com/store/account/subscriptions?package=fr.histoiresdusoir.app');
  final url = await ref.read(purchasesRepositoryProvider).managementUrl().catchError((Object _) => null);
  if (context.mounted) await openExternal(context, ref, url ?? storePage);
}

class _Section extends StatelessWidget {
  const _Section({required this.image, required this.title, required this.subtitle, this.onTap});

  final String image;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(image, width: 44, excludeFromSemantics: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

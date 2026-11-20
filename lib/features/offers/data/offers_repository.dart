import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failure.dart';
import '../../catalog/domain/story_theme.dart';
import '../../session/data/session_repository.dart';
import '../domain/credits.dart';

class Entitlements {
  const Entitlements({
    required this.freeStoriesLeft,
    this.isPremium = false,
    this.premiumUntil,
    this.hasVoicePack = false,
    this.isAnonymous = true,
    this.credits = const {},
  });

  factory Entitlements.fromJson(Map<String, dynamic> json) => Entitlements(
    freeStoriesLeft: json['free_stories_left'] as int,
    isPremium: json['is_premium'] as bool,
    premiumUntil: DateTime.tryParse(json['premium_until'] as String? ?? '')?.toLocal(),
    hasVoicePack: json['has_voice_pack'] as bool? ?? false,
    isAnonymous: json['is_anonymous'] as bool,
    credits: {
      for (final MapEntry(:key, :value) in (json['credits'] as Map<String, dynamic>? ?? const {}).entries)
        CreditScope.fromDb(key): value as int,
    },
  );

  final int freeStoriesLeft;
  final bool isPremium;
  final DateTime? premiumUntil;

  /// Pack Voix acheté (achat définitif, US-37).
  final bool hasVoicePack;

  /// Voix apaisantes ouvertes (US-36) ; en gratuit, une écoute par histoire reste la règle.
  bool get canUsePremiumVoices => isPremium || hasVoicePack;

  /// Pas encore de compte parent : requis avant tout achat (ADR-010).
  final bool isAnonymous;

  /// Soldes positifs par portée ; montrés aux parents seulement (US-35).
  final Map<CreditScope, int> credits;

  /// Crédit que le serveur consommera pour cette histoire, dans le même ordre (H8, H16).
  CreditScope? creditFor(StoryTheme theme, {required bool personalized}) {
    bool has(CreditScope scope) => (credits[scope] ?? 0) > 0;
    if (theme.id == 'noel' && has(CreditScope.noel)) return CreditScope.noel;
    if (!personalized && theme.tier == ThemeTier.premium && has(CreditScope.premiumThemes)) {
      return CreditScope.premiumThemes;
    }
    if (personalized && has(CreditScope.custom)) return CreditScope.custom;
    return has(CreditScope.generic) ? CreditScope.generic : null;
  }

  // Ce que l'enfant peut ouvrir, sans voir ni crédit ni prix. Le serveur revérifie tout.
  bool canPersonalize(StoryTheme theme) => isPremium || creditFor(theme, personalized: true) != null;

  bool canUseTheme(StoryTheme theme) =>
      isPremium || theme.isFree || creditFor(theme, personalized: false) != null || canPersonalize(theme);

  bool canChooseDuration(StoryTheme theme, {required bool personalized}) =>
      isPremium || creditFor(theme, personalized: personalized) != null;
}

class OffersRepository {
  const OffersRepository(this._db);

  final SupabaseClient _db;

  /// Droits calculés par le serveur (ADR-003).
  Future<Entitlements> entitlements() =>
      guard(() async => Entitlements.fromJson(await _db.rpc<Map<String, dynamic>>('my_entitlements')));

  /// Packs proposés, dans l'ordre du catalogue.
  Future<List<CreditPack>> creditPacks() => guard(() async {
    final rows = await _db
        .from('credit_packs')
        .select('product_id, scope, credits, name, description')
        .order('sort_order', ascending: true);
    return rows.map(CreditPack.fromJson).toList();
  });
}

final offersRepositoryProvider = Provider((ref) => OffersRepository(Supabase.instance.client));

final entitlementsProvider = FutureProvider((ref) {
  ref.watch(accountProvider);
  return ref.watch(offersRepositoryProvider).entitlements();
});

final creditPacksProvider = FutureProvider.autoDispose((ref) => ref.watch(offersRepositoryProvider).creditPacks());

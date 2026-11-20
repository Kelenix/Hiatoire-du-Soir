import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config.dart';
import '../../../core/failure.dart';
import '../domain/premium_plan.dart';

/// Achats intégrés via RevenueCat (ADR-009). L'identifiant RevenueCat est celui du compte Supabase :
/// le webhook retrouve ainsi l'acheteur. Les droits, eux, se lisent toujours dans Supabase.
class PurchasesRepository {
  PurchasesRepository(this._auth);

  final GoTrueClient _auth;
  String? _identifiedUser;
  final _packages = <String, Package>{};
  final _products = <String, StoreProduct>{};

  static String get _apiKey => Platform.isIOS ? AppConfig.revenueCatIosKey : AppConfig.revenueCatAndroidKey;

  /// Formules annuelle et mensuelle de l'offre courante ; vide si le store ne répond pas.
  Future<List<PremiumPlan>> plans() => _guardPurchases(() async {
    await _identify();
    final offering = (await Purchases.getOfferings()).current;
    final packages = [offering?.annual, offering?.monthly].whereType<Package>();
    _packages
      ..clear()
      ..addEntries(packages.map((package) => MapEntry(package.identifier, package)));
    return packages.map(_toPlan).toList();
  });

  /// Renvoie `false` si le parent annule l'achat ; les droits arrivent ensuite par le webhook.
  Future<bool> purchase(PremiumPlan plan) => _buy(PurchaseParams.package(_packages[plan.id]!));

  /// Prix des packs fournis par le store, par identifiant de produit (US-33).
  Future<Map<String, String>> packPrices(List<String> productIds) => _guardPurchases(() async {
    await _identify();
    final products = await Purchases.getProducts(productIds, productCategory: ProductCategory.nonSubscription);
    _products
      ..clear()
      ..addEntries(products.map((product) => MapEntry(product.identifier, product)));
    return {for (final product in products) product.identifier: product.priceString};
  });

  /// Renvoie `false` si le parent annule ; les crédits arrivent ensuite par le webhook (US-34).
  Future<bool> buyPack(String productId) => _buy(PurchaseParams.storeProduct(_products[productId]!));

  Future<bool> _buy(PurchaseParams params) => _guardPurchases(() async {
    await _identify();
    try {
      await Purchases.purchase(params);
      return true;
    } on PlatformException catch (error) {
      if (PurchasesErrorHelper.getErrorCode(error) == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  });

  Future<void> restore() => _guardPurchases(() async {
    await _identify();
    await Purchases.restorePurchases();
  });

  /// Page du store où le parent gère ou résilie son abonnement (US-26).
  Future<Uri?> managementUrl() => _guardPurchases(() async {
    await _identify();
    return Uri.tryParse((await Purchases.getCustomerInfo()).managementURL ?? '');
  });

  Future<void> _identify() async {
    final userId = _auth.currentUser!.id;
    if (_identifiedUser == userId) return;
    if (_identifiedUser == null) {
      await Purchases.configure(PurchasesConfiguration(_apiKey)..appUserID = userId);
    } else {
      await Purchases.logIn(userId);
    }
    _identifiedUser = userId;
  }

  static PremiumPlan _toPlan(Package package) {
    final product = package.storeProduct;
    return PremiumPlan(
      id: package.identifier,
      period: package.packageType == PackageType.annual ? PlanPeriod.annual : PlanPeriod.monthly,
      price: product.price,
      priceLabel: product.priceString,
      currencyCode: product.currencyCode,
      hasFreeTrial: product.introductoryPrice?.price == 0,
    );
  }

  static Future<T> _guardPurchases<T>(Future<T> Function() call) async {
    if (_apiKey.isEmpty) throw Failure.unexpected;
    try {
      return await call();
    } on PlatformException catch (error) {
      throw PurchasesErrorHelper.getErrorCode(error) == PurchasesErrorCode.networkError
          ? Failure.offline
          : Failure.unexpected;
    }
  }
}

final purchasesRepositoryProvider = Provider((ref) => PurchasesRepository(Supabase.instance.client.auth));

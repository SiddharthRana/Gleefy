import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show ProductType;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// The Premium unlock as the store shows it (price is localised by Google Play).
class StoreOffer {
  const StoreOffer({required this.productId, required this.price, this.raw});

  final String productId;
  final String price;

  /// Plugin object needed to start the purchase (null in tests).
  final Object? raw;
}

enum StorePurchaseStatus { pending, purchased, restored, error, canceled }

class StorePurchaseUpdate {
  const StorePurchaseUpdate({required this.status, this.purchaseToken, this.errorMessage, this.raw});

  final StorePurchaseStatus status;
  final String? purchaseToken;
  final String? errorMessage;
  final Object? raw;
}

/// Store boundary (Google Play via in_app_purchase). Tests use a fake.
abstract class BillingGateway {
  Future<bool> isAvailable();

  /// The one-time (non-consumable) Premium product, or null when the store doesn't offer it.
  Future<StoreOffer?> loadOffer(String productId);

  /// [accountRef] is sent as the obfuscated account id so the server can bind the purchase to the user.
  Future<void> buy(StoreOffer offer, {required String accountRef});
  Stream<StorePurchaseUpdate> get purchases;

  /// Finishes a purchase on the device after the server verified (and acknowledged) it.
  Future<void> complete(StorePurchaseUpdate update);
  Future<void> restore();
}

class PlayBillingGateway implements BillingGateway {
  PlayBillingGateway(this._iap);

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<StoreOffer?> loadOffer(String productId) async {
    final res = await _iap.queryProductDetails({productId});
    final details = res.productDetails.whereType<GooglePlayProductDetails>().where(
      (d) => d.id == productId && d.productDetails.productType == ProductType.inapp,
    );
    final d = details.firstOrNull;
    return d == null ? null : StoreOffer(productId: d.id, price: d.price, raw: d);
  }

  @override
  Future<void> buy(StoreOffer offer, {required String accountRef}) async {
    final details = offer.raw! as GooglePlayProductDetails;
    // Non-consumable: bought once; the server acknowledges it, so Play keeps it for restores.
    await _iap.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(productDetails: details, applicationUserName: accountRef),
    );
  }

  @override
  Stream<StorePurchaseUpdate> get purchases => _iap.purchaseStream.expand(
    (list) => list.map(
      (p) => StorePurchaseUpdate(
        status: switch (p.status) {
          PurchaseStatus.pending => StorePurchaseStatus.pending,
          PurchaseStatus.purchased => StorePurchaseStatus.purchased,
          PurchaseStatus.restored => StorePurchaseStatus.restored,
          PurchaseStatus.canceled => StorePurchaseStatus.canceled,
          PurchaseStatus.error => StorePurchaseStatus.error,
        },
        purchaseToken: p.verificationData.serverVerificationData,
        errorMessage: p.error?.message,
        raw: p,
      ),
    ),
  );

  @override
  Future<void> complete(StorePurchaseUpdate update) async {
    final p = update.raw;
    if (p is PurchaseDetails && p.pendingCompletePurchase) await _iap.completePurchase(p);
  }

  @override
  Future<void> restore() => _iap.restorePurchases();
}

/// Used where Google Play isn't available (iOS, desktop, tests by default).
class UnavailableBillingGateway implements BillingGateway {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<StoreOffer?> loadOffer(String productId) async => null;
  @override
  Future<void> buy(StoreOffer offer, {required String accountRef}) async {}
  @override
  Stream<StorePurchaseUpdate> get purchases => const Stream.empty();
  @override
  Future<void> complete(StorePurchaseUpdate update) async {}
  @override
  Future<void> restore() async {}
}

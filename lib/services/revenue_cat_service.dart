import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';

// TODO(backend): Set real RevenueCat API key from environment config
// ignore: unused_element
const _kRevenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';

// TODO(backend): Set real product IDs from App Store / Play Store
// ignore: unused_element
const _kMonthlyProductId = 'luminary_monthly';
// ignore: unused_element
const _kAnnualProductId = 'luminary_annual';

class RevenueCatService {
  final Ref _ref;
  RevenueCatService(this._ref);

  /// Call once at app start after Firebase.initializeApp().
  /// TODO(backend): Purchases.configure(PurchasesConfiguration(_kRevenueCatApiKey))
  Future<void> initialize() async {
    // TODO(backend): await Purchases.configure(PurchasesConfiguration(_kRevenueCatApiKey));
    // TODO(backend): Purchases.setLogLevel(LogLevel.debug); // dev only
    // TODO(backend): Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
  }

  /// Fetch available offerings from RevenueCat.
  /// TODO(backend): return await Purchases.getOfferings()
  Future<void> getOfferings() async {
    // TODO(backend): final offerings = await Purchases.getOfferings();
  }

  /// Purchase the monthly plan.
  /// On success, updates UserProfileProvider.subscriptionStatus to active.
  Future<bool> purchaseMonthly() async {
    // TODO(backend): final package = (await Purchases.getOfferings()).current?.monthly;
    // TODO(backend): if (package == null) return false;
    // TODO(backend): await Purchases.purchasePackage(package);
    await Future.delayed(const Duration(milliseconds: 800));
    _ref.read(userProfileProvider.notifier)
        .setSubscriptionStatus(SubscriptionStatus.active);
    return true;
  }

  /// Purchase the annual plan.
  /// On success, updates UserProfileProvider.subscriptionStatus to active.
  Future<bool> purchaseAnnual() async {
    // TODO(backend): final package = (await Purchases.getOfferings()).current?.annual;
    // TODO(backend): if (package == null) return false;
    // TODO(backend): await Purchases.purchasePackage(package);
    await Future.delayed(const Duration(milliseconds: 800));
    _ref.read(userProfileProvider.notifier)
        .setSubscriptionStatus(SubscriptionStatus.active);
    return true;
  }

  /// Restore purchases. On success, updates subscription status.
  Future<bool> restorePurchases() async {
    // TODO(backend): final info = await Purchases.restorePurchases();
    // TODO(backend): if (info.entitlements.active.isNotEmpty) { setStatus(active); }
    await Future.delayed(const Duration(milliseconds: 600));
    return false; // mock: no purchases to restore
  }

  // ignore: unused_element
  void _onCustomerInfoUpdate(dynamic info) {
    // TODO(backend): parse CustomerInfo and call setSubscriptionStatus accordingly
  }
}

final revenueCatServiceProvider = Provider<RevenueCatService>(
  (ref) => RevenueCatService(ref),
);

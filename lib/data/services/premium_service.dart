import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumService {
  Future<void> init() async {
    // TODO: configure keys per platform
    // await Purchases.configure(PurchasesConfiguration('appl_xxx_ios_key'));
    // await Purchases.configure(PurchasesConfiguration('goog_xxx_android_key'));
  }

  Future<bool> isPremiumActive() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('premium'); // change to your entitlement id
    } catch (_) {
      return false;
    }
  }
}

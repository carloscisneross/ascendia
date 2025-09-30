import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';

class PremiumService {
  bool _isInitialized = false;
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Configure RevenueCat with platform-specific keys
      final configuration = PurchasesConfiguration(
        defaultTargetPlatform == TargetPlatform.iOS 
          ? AppConstants.revenueCatApiKeyIOS 
          : AppConstants.revenueCatApiKeyAndroid
      );
      
      await Purchases.configure(configuration);
      
      // Enable debug logs in debug mode
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      
      _isInitialized = true;
      debugPrint('PremiumService: RevenueCat configured successfully');
    } catch (e) {
      debugPrint('PremiumService: Failed to configure RevenueCat: $e');
      // Don't throw - app should still work without RevenueCat
    }
  }

  Future<bool> isPremiumActive() async {
    if (!_isInitialized) {
      await init();
    }
    
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive = customerInfo.entitlements.active.containsKey(AppConstants.premiumEntitlementId);
      debugPrint('PremiumService: Premium status check - $isActive');
      return isActive;
    } catch (e) {
      debugPrint('PremiumService: Error checking premium status: $e');
      return false;
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    if (!_isInitialized) {
      await init();
    }
    return await Purchases.restorePurchases();
  }

  Future<Offerings> getOfferings() async {
    if (!_isInitialized) {
      await init();
    }
    return await Purchases.getOfferings();
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    if (!_isInitialized) {
      await init();
    }
    
    final purchaserInfo = await Purchases.purchasePackage(package);
    
    // Update Firestore isPremium field if purchase successful
    if (purchaserInfo.entitlements.active.containsKey(AppConstants.premiumEntitlementId)) {
      await _updateFirestorePremiumStatus(true);
    }
    
    return purchaserInfo;
  }

  Future<void> loginUser(String userId) async {
    if (!_isInitialized) {
      await init();
    }
    await Purchases.logIn(userId);
  }

  Future<void> logoutUser() async {
    if (!_isInitialized) return;
    await Purchases.logOut();
  }

  /// Updates the user's isPremium status in Firestore
  Future<void> _updateFirestorePremiumStatus(bool isPremium) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isPremium': isPremium});
        debugPrint('PremiumService: Updated Firestore isPremium to $isPremium');
      }
    } catch (e) {
      debugPrint('PremiumService: Failed to update Firestore isPremium: $e');
    }
  }
}

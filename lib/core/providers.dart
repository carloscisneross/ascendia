import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/auth_service.dart';
import '../data/services/premium_service.dart';
import '../data/models/models.dart';

/// Authentication state provider - streams the current user
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user provider - synchronous access to current user
final currentUserProvider = Provider<User?>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.when(
    data: (user) => user,
    error: (_, __) => null,
    loading: () => null,
  );
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Premium service provider  
final premiumServiceProvider = Provider<PremiumService>((ref) {
  return PremiumService();
});

/// User profile document provider - streams user's Firestore profile
final userProfileProvider = StreamProvider.family<DocumentSnapshot?, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots();
});

/// Premium status provider - checks RevenueCat entitlement
final premiumStatusProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.read(premiumServiceProvider);
  try {
    return await premiumService.isPremiumActive();
  } catch (e) {
    // Fallback to Firestore isPremium field if RevenueCat fails
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final profileSnapshot = await ref.read(userProfileProvider(user.uid).future);
      if (profileSnapshot != null && profileSnapshot.exists) {
        final data = profileSnapshot.data() as Map<String, dynamic>?;
        return data?['isPremium'] ?? false;
      }
    }
    return false;
  }
});

/// Current streak days provider - calculates streak from profile data
final currentStreakProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  
  final profileAsync = ref.watch(userProfileProvider(user.uid));
  return profileAsync.when(
    data: (snapshot) {
      if (snapshot?.exists != true) return 0;
      final data = snapshot!.data() as Map<String, dynamic>;
      final streakStartedAt = (data['streakStartedAt'] as Timestamp?)?.toDate();
      if (streakStartedAt == null) return 0;
      
      final now = DateTime.now();
      final difference = now.difference(streakStartedAt);
      return difference.inDays + 1; // Include the start day
    },
    error: (_, __) => 0,
    loading: () => 0,
  );
});

/// Is authenticated provider - convenience provider  
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
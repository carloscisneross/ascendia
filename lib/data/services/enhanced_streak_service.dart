import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Enhanced streak service that handles daily check-ins and automatic resets
class EnhancedStreakService {
  static final EnhancedStreakService _instance = EnhancedStreakService._instance();
  factory EnhancedStreakService() => _instance;
  EnhancedStreakService._instance();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate current streak days from streakStartedAt
  int calculateStreakDays(DateTime streakStartedAt) {
    final now = DateTime.now();
    final difference = now.difference(streakStartedAt);
    return difference.inDays + 1; // Include the start day
  }

  /// Check if streak should be reset due to missed day(s)
  bool shouldResetStreak(DateTime streakStartedAt, DateTime? lastCheckIn) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    // If no previous check-in, use streak start date
    final lastActivity = lastCheckIn ?? streakStartedAt;
    final lastActivityDay = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
    
    // Calculate days since last activity
    final daysSinceLastActivity = startOfToday.difference(lastActivityDay).inDays;
    
    // If more than 1 day has passed, streak should be reset
    return daysSinceLastActivity > 1;
  }

  /// Perform daily check-in and return updated streak info
  Future<StreakCheckInResult> performCheckIn(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final data = userDoc.data()!;
      final streakStartedAt = (data['streakStartedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final lastCheckIn = (data['lastCheckIn'] as Timestamp?)?.toDate();
      final currentStreak = calculateStreakDays(streakStartedAt);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCheckInDay = lastCheckIn != null 
          ? DateTime(lastCheckIn.year, lastCheckIn.month, lastCheckIn.day)
          : null;

      // Check if already checked in today
      if (lastCheckInDay != null && lastCheckInDay.isAtSameMomentAs(today)) {
        return StreakCheckInResult(
          success: true,
          streakDays: currentStreak,
          message: 'Already checked in today!',
          isNewRecord: false,
        );
      }

      // Check if streak should be reset
      if (shouldResetStreak(streakStartedAt, lastCheckIn)) {
        // Reset streak
        final resetTimestamp = Timestamp.now();
        await _firestore.collection('users').doc(userId).update({
          'streakStartedAt': resetTimestamp,
          'lastCheckIn': resetTimestamp,
          'resetHistory': FieldValue.arrayUnion([{
            'resetAt': resetTimestamp,
            'motive': 'Missed day - auto reset',
            'note': 'Streak automatically reset due to missed check-in',
          }]),
          'updatedAt': resetTimestamp,
        });

        return StreakCheckInResult(
          success: true,
          streakDays: 1,
          message: 'Streak reset due to missed day. Starting fresh!',
          isNewRecord: false,
          wasReset: true,
        );
      } else {
        // Continue streak - just update last check-in
        final newStreak = calculateStreakDays(streakStartedAt);
        await _firestore.collection('users').doc(userId).update({
          'lastCheckIn': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Check if this is a new personal record
        final previousBest = data['bestStreak'] as int? ?? 0;
        final isNewRecord = newStreak > previousBest;
        
        if (isNewRecord) {
          await _firestore.collection('users').doc(userId).update({
            'bestStreak': newStreak,
          });
        }

        return StreakCheckInResult(
          success: true,
          streakDays: newStreak,
          message: isNewRecord 
              ? '🎉 New personal record: $newStreak days!'
              : 'Day $newStreak complete!',
          isNewRecord: isNewRecord,
        );
      }

    } catch (e) {
      debugPrint('Error performing check-in: $e');
      return StreakCheckInResult(
        success: false,
        streakDays: 0,
        message: 'Failed to check in. Please try again.',
        isNewRecord: false,
      );
    }
  }

  /// Get streak status without performing check-in
  Future<StreakStatus> getStreakStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return StreakStatus(
          currentStreak: 0,
          canCheckInToday: true,
          hasCheckedInToday: false,
          streakAtRisk: false,
        );
      }

      final data = userDoc.data()!;
      final streakStartedAt = (data['streakStartedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final lastCheckIn = (data['lastCheckIn'] as Timestamp?)?.toDate();
      final currentStreak = calculateStreakDays(streakStartedAt);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCheckInDay = lastCheckIn != null 
          ? DateTime(lastCheckIn.year, lastCheckIn.month, lastCheckIn.day)
          : null;

      final hasCheckedInToday = lastCheckInDay != null && lastCheckInDay.isAtSameMomentAs(today);
      final streakAtRisk = shouldResetStreak(streakStartedAt, lastCheckIn);

      return StreakStatus(
        currentStreak: streakAtRisk ? 0 : currentStreak,
        canCheckInToday: !hasCheckedInToday && !streakAtRisk,
        hasCheckedInToday: hasCheckedInToday,
        streakAtRisk: streakAtRisk,
        lastCheckIn: lastCheckIn,
      );

    } catch (e) {
      debugPrint('Error getting streak status: $e');
      return StreakStatus(
        currentStreak: 0,
        canCheckInToday: true,
        hasCheckedInToday: false,
        streakAtRisk: false,
      );
    }
  }
}

/// Result of a check-in operation
class StreakCheckInResult {
  final bool success;
  final int streakDays;
  final String message;
  final bool isNewRecord;
  final bool wasReset;

  StreakCheckInResult({
    required this.success,
    required this.streakDays,
    required this.message,
    required this.isNewRecord,
    this.wasReset = false,
  });
}

/// Current streak status
class StreakStatus {
  final int currentStreak;
  final bool canCheckInToday;
  final bool hasCheckedInToday;
  final bool streakAtRisk;
  final DateTime? lastCheckIn;

  StreakStatus({
    required this.currentStreak,
    required this.canCheckInToday,
    required this.hasCheckedInToday,
    required this.streakAtRisk,
    this.lastCheckIn,
  });
}
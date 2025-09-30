import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/medal_service.dart';
import '../../data/services/enhanced_streak_service.dart';
import '../../data/models/models.dart';
import '../../core/providers.dart';

/// Medal service provider
final medalServiceProvider = Provider<MedalService>((ref) {
  return MedalService();
});

/// Enhanced streak service provider
final enhancedStreakServiceProvider = Provider<EnhancedStreakService>((ref) {
  return EnhancedStreakService();
});

/// Personal medals provider - loads all personal medals
final personalMedalsProvider = FutureProvider<List<MedalSpec>>((ref) async {
  final medalService = ref.read(medalServiceProvider);
  await medalService.loadMedals();
  return medalService.personalMedals;
});

/// Guild medals provider - loads all guild medals
final guildMedalsProvider = FutureProvider<List<MedalSpec>>((ref) async {
  final medalService = ref.read(medalServiceProvider);
  await medalService.loadMedals();
  return medalService.guildMedals;
});

/// World medals provider - loads all world medals  
final worldMedalsProvider = FutureProvider<List<MedalSpec>>((ref) async {
  final medalService = ref.read(medalServiceProvider);
  await medalService.loadMedals();
  return medalService.worldMedals;
});

/// Progression items provider - loads progression milestones
final progressionItemsProvider = FutureProvider<List<ProgressionItem>>((ref) async {
  final medalService = ref.read(medalServiceProvider);
  await medalService.loadMedals();
  return medalService.progressionItems;
});

/// Earned medals provider - medals user has earned based on current streak
final earnedMedalsProvider = FutureProvider<List<MedalSpec>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return [];

  final streakDays = ref.watch(currentStreakProvider);
  final medalService = ref.read(medalServiceProvider);
  
  await medalService.loadMedals();
  return medalService.getEarnedPersonalMedals(streakDays);
});

/// Next medal provider - next medal user can earn
final nextMedalProvider = FutureProvider<MedalSpec?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  final streakDays = ref.watch(currentStreakProvider);
  final medalService = ref.read(medalServiceProvider);
  
  await medalService.loadMedals();
  return medalService.getNextPersonalMedal(streakDays);
});

/// Current progression provider - current progression milestone achieved
final currentProgressionProvider = FutureProvider<ProgressionItem?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  final streakDays = ref.watch(currentStreakProvider);
  final medalService = ref.read(medalServiceProvider);
  
  await medalService.loadMedals();
  return medalService.getCurrentProgression(streakDays);
});

/// Next progression provider - next progression milestone
final nextProgressionProvider = FutureProvider<ProgressionItem?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  final streakDays = ref.watch(currentStreakProvider);
  final medalService = ref.read(medalServiceProvider);
  
  await medalService.loadMedals();
  return medalService.getNextProgression(streakDays);
});

/// Streak status provider - current streak status
final streakStatusProvider = FutureProvider<StreakStatus>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return StreakStatus(
      currentStreak: 0,
      canCheckInToday: false,
      hasCheckedInToday: false,
      streakAtRisk: false,
    );
  }

  final streakService = ref.read(enhancedStreakServiceProvider);
  return await streakService.getStreakStatus(user.uid);
});

/// Check-in provider - for performing daily check-ins
final checkInProvider = FutureProvider.family<StreakCheckInResult, String>((ref, userId) async {
  final streakService = ref.read(enhancedStreakServiceProvider);
  return await streakService.performCheckIn(userId);
});
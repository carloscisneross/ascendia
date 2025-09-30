import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// Service that manages medal loading and awarding logic
class MedalService {
  static final MedalService _instance = MedalService._internal();
  factory MedalService() => _instance;
  MedalService._internal();

  List<MedalSpec>? _personalMedals;
  List<MedalSpec>? _guildMedals;
  List<MedalSpec>? _worldMedals;
  List<ProgressionItem>? _progressionItems;

  /// Load all medals from the master manifest
  Future<void> loadMedals() async {
    if (_personalMedals != null) return; // Already loaded

    try {
      final manifestString = await rootBundle.loadString('assets/manifests/medals_master_manifest.json');
      final manifest = json.decode(manifestString) as Map<String, dynamic>;

      // Load personal medals
      _personalMedals = (manifest['personal'] as List).map((item) {
        return MedalSpec(
          category: MedalCategory.personal,
          id: item['level'] as int,
          name: item['name'] as String,
          normalAssetPath: item['normal'] as String,
          smallAssetPath: item['small'] as String,
          durationDays: item['duration_days'] as int?,
        );
      }).toList();

      // Load guild medals
      _guildMedals = (manifest['guild'] as List).map((item) {
        return MedalSpec(
          category: MedalCategory.guild,
          id: item['level'] as int,
          name: item['name'] as String,
          normalAssetPath: item['normal'] as String,
          smallAssetPath: item['small'] as String,
        );
      }).toList();

      // Load world medals
      _worldMedals = (manifest['world'] as List).map((item) {
        return MedalSpec(
          category: MedalCategory.world,
          id: item['key'] as String,
          name: item['name'] as String,
          normalAssetPath: item['normal'] as String,
          smallAssetPath: item['small'] as String,
        );
      }).toList();

      // Load progression items
      await _loadProgression();

    } catch (e) {
      throw Exception('Failed to load medals: $e');
    }
  }

  Future<void> _loadProgression() async {
    try {
      final progressionString = await rootBundle.loadString('assets/manifests/progression.json');
      final progression = json.decode(progressionString) as Map<String, dynamic>;

      _progressionItems = (progression['items'] as List).map((item) {
        return ProgressionItem(
          milestone: item['milestone'] as String,
          title: item['title'] as String,
          reports: List<String>.from(item['reports'] as List),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load progression: $e');
    }
  }

  /// Get all personal medals
  List<MedalSpec> get personalMedals => _personalMedals ?? [];

  /// Get all guild medals  
  List<MedalSpec> get guildMedals => _guildMedals ?? [];

  /// Get all world medals
  List<MedalSpec> get worldMedals => _worldMedals ?? [];

  /// Get progression items
  List<ProgressionItem> get progressionItems => _progressionItems ?? [];

  /// Get earned personal medals based on streak days
  List<MedalSpec> getEarnedPersonalMedals(int streakDays) {
    return personalMedals.where((medal) {
      final requiredDays = medal.durationDays ?? 0;
      return streakDays >= requiredDays;
    }).toList();
  }

  /// Get the next personal medal to earn
  MedalSpec? getNextPersonalMedal(int streakDays) {
    final unearned = personalMedals.where((medal) {
      final requiredDays = medal.durationDays ?? 0;
      return streakDays < requiredDays;
    }).toList();

    if (unearned.isEmpty) return null;

    // Sort by duration and return the first (lowest requirement)
    unearned.sort((a, b) => (a.durationDays ?? 0).compareTo(b.durationDays ?? 0));
    return unearned.first;
  }

  /// Get progression item for current streak
  ProgressionItem? getCurrentProgression(int streakDays) {
    // Find the closest progression item that the user has achieved
    ProgressionItem? current;
    
    for (final item in progressionItems) {
      final milestone = item.milestone;
      final requiredDays = _parseMilestoneToDays(milestone);
      
      if (streakDays >= requiredDays) {
        current = item;
      } else {
        break;
      }
    }
    
    return current;
  }

  /// Get next progression milestone
  ProgressionItem? getNextProgression(int streakDays) {
    for (final item in progressionItems) {
      final milestone = item.milestone;
      final requiredDays = _parseMilestoneToDays(milestone);
      
      if (streakDays < requiredDays) {
        return item;
      }
    }
    return null;
  }

  /// Parse milestone string to days (e.g., "7 Days" -> 7, "1 Month" -> 30)
  int _parseMilestoneToDays(String milestone) {
    final lower = milestone.toLowerCase();
    
    if (lower.contains('7 days')) return 7;
    if (lower.contains('2 weeks')) return 14;
    if (lower.contains('3 weeks')) return 21;
    if (lower.contains('1 month')) return 30;
    if (lower.contains('3 months')) return 90;
    if (lower.contains('6 months')) return 180;
    if (lower.contains('1 year')) return 365;
    if (lower.contains('1.5 years')) return 547;
    if (lower.contains('2 years')) return 730;
    if (lower.contains('3 years')) return 1095;
    if (lower.contains('4 years')) return 1460;
    if (lower.contains('5 years')) return 1825;
    
    // Default fallback
    return 0;
  }

  /// Check if a new medal was earned (used for notifications)
  List<MedalSpec> checkNewMedalsEarned(int previousStreakDays, int currentStreakDays) {
    final previousEarned = getEarnedPersonalMedals(previousStreakDays);
    final currentEarned = getEarnedPersonalMedals(currentStreakDays);
    
    // Find newly earned medals
    final newMedals = currentEarned.where((medal) {
      return !previousEarned.any((prev) => prev.id == medal.id);
    }).toList();
    
    return newMedals;
  }
}
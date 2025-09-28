import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';

/// Service that manages the user's streak/profile and reads asset manifests
/// (medals, progression). Now also persists/reads the user's selected avatar.
class StreakService {
  // ----- Profile / Streak -----
  Profile _profile = Profile(
    userId: 'demo-user',
    username: 'Ascender',
    streakStartedAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
    goalInDays: 7,
    isPremium: false,
    resetHistory: const [],
  );

  /// Emits the live duration since `streakStartedAt` every second.
  Stream<Duration> get liveStreakDuration {
    return Stream.periodic(const Duration(seconds: 1), (computationCount) {
      return DateTime.now().difference(_profile.streakStartedAt);
    });
  }

  Profile get currentProfile => _profile;

  Future<void> resetStreak({required String motive, String? note}) async {
    // Simulate network latency / call
    await Future.delayed(const Duration(milliseconds: 500));

    final reset = StreakReset(resetAt: DateTime.now(), motive: motive, note: note);

    // Update the local mock profile
    _profile = Profile(
      userId: _profile.userId,
      username: _profile.username,
      streakStartedAt: DateTime.now(),
      goalInDays: _profile.goalInDays,
      isPremium: _profile.isPremium,
      resetHistory: [..._profile.resetHistory, reset],
    );
  }

  // ----- Avatar persistence -----
  static const _avatarPrefsKey = 'selected_avatar_path';
  String? _selectedAvatarPath;

  /// Returns the currently selected avatar asset path (if any).
  String? get selectedAvatarPath => _selectedAvatarPath;

  /// Load saved avatar from SharedPreferences into memory.
  Future<void> loadAvatar() async {
    final sp = await SharedPreferences.getInstance();
    _selectedAvatarPath = sp.getString(_avatarPrefsKey);
  }

  /// Save and update the selected avatar path.
  Future<void> setAvatar(String assetPath) async {
    _selectedAvatarPath = assetPath;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_avatarPrefsKey, assetPath);
  }

  // ----- Manifests: medals & progression -----
  final List<MedalSpec> _personalMedals = [];
  final List<MedalSpec> _guildMedals = [];
  final List<MedalSpec> _worldMedals = [];
  final List<ProgressionItem> _progressionItems = [];

  bool _manifestsLoaded = false;

  /// Call once at startup (or lazy-load) to read all JSON manifests.
  Future<void> ensureManifestsLoaded() async {
    if (_manifestsLoaded) return;
    await Future.wait([
      _loadPersonalMedals(),
      _loadGuildMedals(),
      _loadWorldMedals(),
      _loadProgression(),
    ]);
    _manifestsLoaded = true;
  }

  List<ProgressionItem> get progressionItems => List.unmodifiable(_progressionItems);

  MedalSpec? getPersonalMedalByLevel(int level) {
    try {
      return _personalMedals.firstWhere(
        (m) => m.category == MedalCategory.personal && (m.id is int && m.id == level),
      );
    } catch (_) {
      return null;
    }
  }

  MedalSpec? getGuildMedalByLevel(int level) {
    try {
      return _guildMedals.firstWhere(
        (m) => m.category == MedalCategory.guild && (m.id is int && m.id == level),
      );
    } catch (_) {
      return null;
    }
  }

  MedalSpec? getWorldMedalByKey(String key) {
    try {
      return _worldMedals.firstWhere(
        (m) => m.category == MedalCategory.world && (m.id is String && m.id == key),
      );
    } catch (_) {
      return null;
    }
  }

  // ----- Internal manifest loaders -----

  Future<void> _loadPersonalMedals() async {
    try {
      final response = await rootBundle.loadString('assets/manifests/personal_medals.json');
      final data = json.decode(response);
      final items = (data['items'] as List).map((item) {
        return MedalSpec(
          category: MedalCategory.personal,
          id: item['level'] as int,
          name: item['name'] as String,
          normalAssetPath: item['asset_normal'] as String,
          smallAssetPath: item['asset_small'] as String,
          durationDays: item['duration_days'] as int?,
        );
      }).toList();
      _personalMedals
        ..clear()
        ..addAll(items);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading personal medals manifest: $e');
    }
  }

  Future<void> _loadGuildMedals() async {
    try {
      final response = await rootBundle.loadString('assets/manifests/guild_medals.json');
      final data = json.decode(response);
      final items = (data['items'] as List).map((item) {
        return MedalSpec(
          category: MedalCategory.guild,
          id: item['level'] as int,
          name: item['name'] as String,
          normalAssetPath: item['asset_normal'] as String,
          smallAssetPath: item['asset_small'] as String,
          durationDays: item['duration_days'] as int?,
        );
      }).toList();
      _guildMedals
        ..clear()
        ..addAll(items);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading guild medals manifest: $e');
    }
  }

  Future<void> _loadWorldMedals() async {
    try {
      final response = await rootBundle.loadString('assets/manifests/world_medals.json');
      final data = json.decode(response);
      final items = (data['items'] as List).map((item) {
        return MedalSpec(
          category: MedalCategory.world,
          id: item['key'] as String,
          name: item['name'] as String,
          normalAssetPath: item['asset_normal'] as String,
          smallAssetPath: item['asset_small'] as String,
          durationDays: item['duration_days'] as int?,
        );
      }).toList();
      _worldMedals
        ..clear()
        ..addAll(items);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading world medals manifest: $e');
    }
  }

  Future<void> _loadProgression() async {
    try {
      final response = await rootBundle.loadString('assets/manifests/progression.json');
      final data = json.decode(response);
      _progressionItems
        ..clear()
        ..addAll((data['items'] as List).map((item) => ProgressionItem(
              milestone: item['milestone'] as String,
              title: item['title'] as String,
              reports: List<String>.from(item['reports'] as List),
            )));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading progression manifest: $e');
    }
  }
}

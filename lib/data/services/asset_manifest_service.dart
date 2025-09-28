import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascendia/data/models/models.dart';

class AssetManifestService {
  List<MedalSpec> _personalMedals = [];
  List<MedalSpec> _guildMedals = [];
  List<MedalSpec> _worldMedals = [];
  List<ProgressionItem> _progressionItems = [];

  Future<void> loadManifests() async {
    await _loadMedalManifest();
    await _loadProgressionManifest();
  }

  Future<void> _loadMedalManifest() async {
    try {
      final String response =
          await rootBundle.loadString('assets/manifests/medals_master_manifest.json');
      final data = await json.decode(response);
      _personalMedals = (data['personal'] as List)
          .map((item) => MedalSpec(
                category: MedalCategory.personal,
                id: item['level'],
                name: item['name'],
                durationDays: item['duration_days'],
                normalAssetPath: item['normal'],
                smallAssetPath: item['small'],
              ))
          .toList();
      _guildMedals = (data['guild'] as List)
          .map((item) => MedalSpec(
                category: MedalCategory.guild,
                id: item['level'],
                name: item['name'],
                normalAssetPath: item['normal'],
                smallAssetPath: item['small'],
              ))
          .toList();
      _worldMedals = (data['world'] as List)
          .map((item) => MedalSpec(
                category: MedalCategory.world,
                id: item['key'],
                name: item['name'],
                normalAssetPath: item['normal'],
                smallAssetPath: item['small'],
              ))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading medal manifest: $e');
    }
  }

  Future<void> _loadProgressionManifest() async {
    try {
      final String response =
          await rootBundle.loadString('assets/manifests/progression.json');
      final data = await json.decode(response);
      _progressionItems = (data['items'] as List)
          .map((item) => ProgressionItem(
                milestone: item['milestone'],
                title: item['title'],
                reports: List<String>.from(item['reports']),
              ))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading progression manifest: $e');
    }
  }

  MedalSpec? getPersonalMedalByLevel(int level) {
    try {
      return _personalMedals.firstWhere((m) => m.id == level);
    } catch (_) {
      return null;
    }
  }
  
  MedalSpec? getNextPersonalMedal(int currentDays) {
     try {
       return _personalMedals
        .where((m) => m.durationDays != null && m.durationDays! > currentDays)
        .first;
     } catch (_) {
       return null;
     }
  }

  List<ProgressionItem> get allProgressionItems => _progressionItems;
}

final assetManifestServiceProvider = Provider<AssetManifestService>((ref) {
  return AssetManifestService();
});

final manifestsProvider = FutureProvider<void>((ref) async {
  await ref.watch(assetManifestServiceProvider).loadManifests();
});

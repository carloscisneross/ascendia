// lib/data/services/avatar_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/avatar.dart';

class AvatarService {
  static const _root = 'assets/avatars/';

  Future<List<Avatar>> loadAll() async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestJson);

    final paths = manifest.keys.where((k) =>
      k.startsWith(_root) &&
      (k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg') || k.endsWith('.webp'))
    );

    final avatars = <Avatar>[];
    for (final p in paths) {
      // Expected: assets/avatars/{male|female|premium}/filename.png
      final rest = p.substring(_root.length);
      final slash = rest.indexOf('/');
      if (slash == -1) continue;

      final folder = rest.substring(0, slash).toLowerCase(); // male | female | premium
      final fileName = p.split('/').last;                    // e.g., male3.png
      final id = fileName.replaceAll(RegExp(r'\.(png|jpg|jpeg|webp)$', caseSensitive: false), '');

      final tier = folder == 'premium' ? AvatarTier.premium : AvatarTier.free;
      final gender = switch (folder) {
        'male'   => AvatarGender.male,
        'female' => AvatarGender.female,
        _        => AvatarGender.unknown,
      };

      avatars.add(Avatar(
        id: id,
        path: p,
        tier: tier,
        gender: gender,
        label: _makeLabel(folder, id),
      ));
    }

    // Sort: free first, then premium; within each, by label
    avatars.sort((a, b) {
      final t = a.tier.index.compareTo(b.tier.index);
      return t != 0 ? t : (a.label ?? a.id).compareTo(b.label ?? b.id);
    });

    return avatars;
  }

  Future<List<Avatar>> loadByTier(AvatarTier tier) async {
    final all = await loadAll();
    return all.where((a) => a.tier == tier).toList();
  }

  String _makeLabel(String folder, String id) {
    // id like male3 -> "Male 3", premium2 -> "Premium 2"
    String prettyFolder = folder[0].toUpperCase() + folder.substring(1);
    final num = RegExp(r'(\d+)$').firstMatch(id)?.group(1);
    return num != null ? '$prettyFolder $num' : prettyFolder;
  }
}

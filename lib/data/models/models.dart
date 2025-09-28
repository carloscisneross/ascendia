import 'package:flutter/material.dart';

// Add this line so Avatar is available app-wide
export 'avatar.dart';

// Using a single file for models for simplicity in this initial phase.

// --- Core Models ---

class Profile {
  final String userId;
  final String username;
  final DateTime streakStartedAt;
  final int goalInDays;
  final bool isPremium;
  final List<StreakReset> resetHistory;

  Profile({
    required this.userId,
    required this.username,
    required this.streakStartedAt,
    this.goalInDays = 7,
    this.isPremium = false,
    this.resetHistory = const [],
  });
}

class Guild {
  final String id;
  final String name;
  final int level;
  final double experience;

  Guild({
    required this.id,
    required this.name,
    required this.level,
    required this.experience,
  });
}

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final int personalMedalLevel;
  final int guildMedalLevel;
  final int cheerCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.personalMedalLevel,
    required this.guildMedalLevel,
    required this.cheerCount,
    required this.createdAt,
  });
}

class StreakReset {
  final DateTime resetAt;
  final String motive;
  final String? note;

  StreakReset({
    required this.resetAt,
    required this.motive,
    this.note,
  });
}

// --- Spec Models (from manifests) ---

enum MedalCategory { personal, guild, world }
enum MedalSize { normal, small }

class MedalSpec {
  final MedalCategory category;
  final dynamic id; // int for level, String for key
  final String name;
  final String normalAssetPath;
  final String smallAssetPath;
  final int? durationDays;

  MedalSpec({
    required this.category,
    required this.id,
    required this.name,
    required this.normalAssetPath,
    required this.smallAssetPath,
    this.durationDays,
  });
}

enum GlowStyle { none, shimmer, electric, flame, prism }

class GlowSpec {
  final bool enabled;
  final List<Color> colors;
  final double intensity;
  final GlowStyle style;

  GlowSpec({
    this.enabled = false,
    this.colors = const [],
    this.intensity = 0.0,
    this.style = GlowStyle.none,
  });

  static GlowSpec get defaultSpec => GlowSpec();
}

class ProgressionItem {
  final String milestone;
  final String title;
  final List<String> reports;

  ProgressionItem({
    required this.milestone,
    required this.title,
    required this.reports,
  });
}

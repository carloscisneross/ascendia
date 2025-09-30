import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../../core/constants.dart';

class ProfileRepository {
  final _col = FirebaseFirestore.instance.collection('users');

  Future<void> ensureProfile(String uid, {String? username, String? avatarKey}) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) {
      final now = Timestamp.now();
      await _col.doc(uid).set({
        'username': username ?? 'Ascender',
        'streakStartedAt': now,
        'goalInDays': AppConstants.defaultStreakGoalDays,
        'isPremium': false,
        'avatarKey': avatarKey ?? AppConstants.defaultFreeAvatarPath,
        'resetHistory': [],
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  Stream<Profile?> watchProfile(String uid) {
    return _col.doc(uid).snapshots().map((d) {
      if (!d.exists) return null;
      final data = d.data()!;
      return Profile(
        userId: uid,
        username: data['username'] ?? 'Ascender',
        streakStartedAt: (data['streakStartedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        goalInDays: (data['goalInDays'] ?? AppConstants.defaultStreakGoalDays) as int,
        isPremium: (data['isPremium'] ?? false) as bool,
        resetHistory: ((data['resetHistory'] ?? []) as List).map((e) => StreakReset(
          resetAt: (e['resetAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          motive: e['motive'] ?? 'unknown',
          note: e['note'],
        )).toList(),
      );
    });
  }

  Future<void> setAvatarKey(String uid, String avatarKey) async {
    await _col.doc(uid).update({
      'avatarKey': avatarKey,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> setPremium(String uid, bool isPremium) async {
    await _col.doc(uid).update({
      'isPremium': isPremium,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> resetStreak(String uid, {required String motive, String? note}) async {
    final now = Timestamp.now();
    await _col.doc(uid).update({
      'streakStartedAt': now,
      'resetHistory': FieldValue.arrayUnion([{
        'resetAt': now,
        'motive': motive,
        'note': note,
      }]),
      'updatedAt': now,
    });
  }

  Future<void> setStreakGoal(String uid, int goalInDays) async {
    await _col.doc(uid).update({
      'goalInDays': goalInDays,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _col.where('username', isEqualTo: username).limit(1).get();
    return query.docs.isEmpty;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class ProfileRepository {
  final _col = FirebaseFirestore.instance.collection('profiles');

  Future<void> ensureProfile(String uid, {String? username}) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) {
      final now = DateTime.now().toUtc();
      await _col.doc(uid).set({
        'username': username ?? 'Ascender',
        'streakStartedAt': now,
        'goalInDays': 7,
        'isPremium': false,
        'resetHistory': [],
        'currentStreakDays': 0,
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
        goalInDays: (data['goalInDays'] ?? 7) as int,
        isPremium: (data['isPremium'] ?? false) as bool,
        resetHistory: ((data['resetHistory'] ?? []) as List).map((e) => StreakReset(
          resetAt: (e['resetAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          motive: e['motive'] ?? 'unknown',
          note: e['note'],
        )).toList(),
      );
    });
  }

  Future<void> setAvatarPath(String uid, String avatarPath) async {
    await _col.doc(uid).set({'avatarPath': avatarPath}, SetOptions(merge: true));
  }

  Future<void> setPremium(String uid, bool isPremium) async {
    await _col.doc(uid).set({'isPremium': isPremium}, SetOptions(merge: true));
  }

  Future<void> resetStreak(String uid, {required String motive, String? note}) async {
    final now = DateTime.now().toUtc();
    await _col.doc(uid).set({
      'streakStartedAt': now,
      'resetHistory': FieldValue.arrayUnion([{
        'resetAt': now,
        'motive': motive,
        'note': note,
      }]),
      'currentStreakDays': 0,
    }, SetOptions(merge: true));
  }

  Future<void> tickStreakDays(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final startedAt = (data['streakStartedAt'] as Timestamp?)?.toDate()?.toUtc() ?? DateTime.now().toUtc();
    final days = DateTime.now().toUtc().difference(startedAt).inDays;
    await _col.doc(uid).set({'currentStreakDays': days}, SetOptions(merge: true));
  }
}

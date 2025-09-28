import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class PostRepository {
  final _col = FirebaseFirestore.instance.collection('posts');

  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String content,
    required int personalMedalLevel,
    required int guildMedalLevel,
  }) async {
    final now = DateTime.now().toUtc();
    await _col.add({
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'personalMedalLevel': personalMedalLevel,
      'guildMedalLevel': guildMedalLevel,
      'cheerCount': 0,
      'createdAt': now,
    });
  }

  Stream<List<Post>> watchFeed({int limit = 100}) {
    return _col.orderBy('createdAt', descending: true).limit(limit).snapshots().map((snap) {
      return snap.docs.map((d) {
        final m = d.data();
        return Post(
          id: d.id,
          authorId: m['authorId'],
          authorName: m['authorName'],
          content: m['content'],
          personalMedalLevel: m['personalMedalLevel'] ?? 0,
          guildMedalLevel: m['guildMedalLevel'] ?? 0,
          cheerCount: m['cheerCount'] ?? 0,
          createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> cheer(String postId) async {
    final ref = _col.doc(postId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final s = await tx.get(ref);
      final current = (s.data()?['cheerCount'] ?? 0) as int;
      tx.update(ref, {'cheerCount': current + 1});
    });
  }
}

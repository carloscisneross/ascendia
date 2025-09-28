import 'package:cloud_firestore/cloud_firestore.dart';

class GuildChatService {
  final _root = FirebaseFirestore.instance.collection('guilds');

  Stream<List<Map<String, dynamic>>> watchMessages(String guildId) {
    return _root.doc(guildId).collection('messages')
      .orderBy('createdAt', descending: true).limit(100).snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> sendMessage({
    required String guildId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    await _root.doc(guildId).collection('messages').add({
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': DateTime.now().toUtc(),
    });
  }
}

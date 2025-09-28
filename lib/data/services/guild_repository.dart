import 'package:cloud_firestore/cloud_firestore.dart';

class GuildRepository {
  final _guilds = FirebaseFirestore.instance.collection('guilds');

  Future<String> createGuild({required String ownerId, required String name}) async {
    final doc = await _guilds.add({
      'ownerId': ownerId,
      'name': name,
      'createdAt': DateTime.now().toUtc(),
    });
    // auto-join owner as member
    await _guilds.doc(doc.id).collection('members').doc(ownerId).set({
      'joinedAt': DateTime.now().toUtc(),
      'role': 'owner',
    });
    return doc.id;
  }

  Future<void> joinGuild({required String guildId, required String userId}) async {
    await _guilds.doc(guildId).collection('members').doc(userId).set({
      'joinedAt': DateTime.now().toUtc(),
      'role': 'member',
    });
  }

  Stream<List<Map<String, dynamic>>> watchGuilds() {
    return _guilds.orderBy('createdAt', descending: true).snapshots().map((snap) =>
      snap.docs.map((d) => {'id': d.id, ...d.data()}).toList()
    );
  }

  Stream<List<Map<String, dynamic>>> watchMembers(String guildId) {
    return _guilds.doc(guildId).collection('members').snapshots().map((snap) =>
      snap.docs.map((d) => {'id': d.id, ...d.data()}).toList()
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/guild_chat_service.dart';

class GuildChatScreen extends StatefulWidget {
  final String guildId;
  final String guildName;
  const GuildChatScreen({super.key, required this.guildId, required this.guildName});

  @override
  State<GuildChatScreen> createState() => _GuildChatScreenState();
}

class _GuildChatScreenState extends State<GuildChatScreen> {
  final _svc = GuildChatService();
  final _text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(widget.guildName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _svc.watchMessages(widget.guildId),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snap.data!;
                if (msgs.isEmpty) return const Center(child: Text('No messages yet.'));
                return ListView.builder(
                  reverse: true, // newest at top
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final isMine = m['authorId'] == user?.uid;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['authorName'] ?? 'user', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(m['text'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: user == null ? null : () async {
                    final t = _text.text.trim();
                    if (t.isEmpty) return;
                    await _svc.sendMessage(
                      guildId: widget.guildId,
                      authorId: user.uid,
                      authorName: user.email?.split('@').first ?? 'Ascender',
                      text: t,
                    );
                    _text.clear();
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

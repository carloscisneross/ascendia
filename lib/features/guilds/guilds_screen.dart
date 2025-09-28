import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/guild_repository.dart';
import 'guild_chat_screen.dart';

class GuildsScreen extends StatefulWidget {
  const GuildsScreen({super.key});

  @override
  State<GuildsScreen> createState() => _GuildsScreenState();
}

class _GuildsScreenState extends State<GuildsScreen> {
  final _repo = GuildRepository();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Guilds')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Create a new guild name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: uid == null ? null : () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    final id = await _repo.createGuild(ownerId: uid, name: name);
                    _nameController.clear();
                    if (!mounted) return;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GuildChatScreen(guildId: id, guildName: name),
                    ));
                  },
                  child: const Text('Create'),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _repo.watchGuilds(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final guilds = snap.data!;
                if (guilds.isEmpty) return const Center(child: Text('No guilds yet. Create one!'));
                return ListView.separated(
                  itemCount: guilds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final g = guilds[i];
                    return ListTile(
                      title: Text(g['name'] ?? 'Guild'),
                      subtitle: Text('Owner: ${g['ownerId'] ?? 'unknown'}'),
                      trailing: ElevatedButton(
                        onPressed: uid == null ? null : () async {
                          await _repo.joinGuild(guildId: g['id'], userId: uid);
                          if (!mounted) return;
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => GuildChatScreen(guildId: g['id'], guildName: g['name'] ?? 'Guild'),
                          ));
                        },
                        child: const Text('Join'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

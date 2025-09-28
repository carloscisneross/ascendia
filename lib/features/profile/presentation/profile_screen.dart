import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/premium_service.dart';
import '../../../data/services/profile_repository.dart';
import '../../../data/services/avatar_service.dart';
import '../../../data/models/avatar.dart';
import 'avatar_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _premium = PremiumService();
  final _profiles = ProfileRepository();
  final _avatars = AvatarService();

  bool _isPremium = false;
  String? _avatarPath;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _premium.init();
    _isPremium = await _premium.isPremiumActive();
    await _profiles.ensureProfile(uid);
    setState(() { _busy = false; });
  }

  Future<String> _fallbackFreeAvatar() async {
    final all = await _avatars.loadAll();
    final free = all.where((a) => a.tier == AvatarTier.free).toList();
    if (free.isNotEmpty) return free.first.path;
    return all.isNotEmpty ? all.first.path : 'assets/avatars/male/male1.png';
  }

  Future<void> _openPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: AvatarPicker(
            onSelected: (a) async {
              if (!_isPremium && a.tier == AvatarTier.premium) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Necesitas Premium para usar este avatar.')),
                  );
                }
                return;
              }
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              await _profiles.setAvatarPath(uid, a.path);
              if (!mounted) return;
              setState(() => _avatarPath = a.path);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<String>(
      future: _avatarPath != null ? Future.value(_avatarPath) : _fallbackFreeAvatar(),
      builder: (context, snap) {
        final path = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 120, height: 120, color: Colors.black12,
                        child: path == null ? const SizedBox.shrink() : Image.asset(path, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _openPicker, child: const Text('Change avatar')),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(_isPremium ? 'Premium active' : 'Free user'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

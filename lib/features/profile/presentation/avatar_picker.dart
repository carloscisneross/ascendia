import 'package:flutter/material.dart';
import '../../../data/models/avatar.dart';
import '../../../data/services/avatar_service.dart';

class AvatarPicker extends StatefulWidget {
  final void Function(Avatar selected) onSelected;
  final bool premiumOnly;
  final bool showPremiumBadges;

  const AvatarPicker({
    super.key,
    required this.onSelected,
    this.premiumOnly = false,
    this.showPremiumBadges = true,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final _service = AvatarService();
  late Future<List<Avatar>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.premiumOnly
        ? _service.loadByTier(AvatarTier.premium)
        : _service.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Avatar>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final avatars = snap.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: avatars.length,
          itemBuilder: (context, i) {
            final a = avatars[i];
            final isPremium = a.tier == AvatarTier.premium;
            return InkWell(
              onTap: () => widget.onSelected(a),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(a.path, fit: BoxFit.cover),
                          ),
                        ),
                        if (widget.showPremiumBadges && isPremium)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.label ?? a.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

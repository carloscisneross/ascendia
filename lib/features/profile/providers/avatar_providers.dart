import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/avatar.dart';
import '../../../data/services/avatar_service.dart';
import '../../../core/providers.dart';

/// Avatar service provider
final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService();
});

/// Avatar catalog provider - loads all avatars from assets
final avatarCatalogProvider = FutureProvider<List<Avatar>>((ref) async {
  final avatarService = ref.read(avatarServiceProvider);
  return await avatarService.loadAll();
});

/// Free avatars provider
final freeAvatarsProvider = FutureProvider<List<Avatar>>((ref) async {
  final avatarService = ref.read(avatarServiceProvider);
  return await avatarService.loadByTier(AvatarTier.free);
});

/// Premium avatars provider
final premiumAvatarsProvider = FutureProvider<List<Avatar>>((ref) async {
  final avatarService = ref.read(avatarServiceProvider);
  return await avatarService.loadByTier(AvatarTier.premium);
});

/// Available avatars provider - returns avatars user can select based on premium status
final availableAvatarsProvider = FutureProvider<List<Avatar>>((ref) async {
  final isPremium = await ref.watch(premiumStatusProvider.future);
  final allAvatars = await ref.watch(avatarCatalogProvider.future);
  
  if (isPremium) {
    return allAvatars; // Premium users get all avatars
  } else {
    return allAvatars.where((avatar) => avatar.tier == AvatarTier.free).toList();
  }
});
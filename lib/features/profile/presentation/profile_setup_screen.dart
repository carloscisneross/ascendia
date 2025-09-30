import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants.dart';
import '../../data/models/avatar.dart';
import '../profile/providers/avatar_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String? _selectedAvatarKey;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _saveAndContinue() async {
    if (_selectedAvatarKey == null) {
      setState(() {
        _errorMessage = 'Please select an avatar to continue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.setAvatarKey(user.uid, _selectedAvatarKey!);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/feed');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _unlockPremium() async {
    if (mounted) {
      final result = await Navigator.of(context).pushNamed('/premium');
      if (result == true) {
        // Premium purchase successful, refresh providers
        ref.invalidate(premiumStatusProvider);
        ref.invalidate(availableAvatarsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremiumAsync = ref.watch(premiumStatusProvider);
    final avatarsAsync = ref.watch(avatarCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Avatar'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.standardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Choose Your Path',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select an avatar to represent your journey',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Avatar Selection
            avatarsAsync.when(
              data: (allAvatars) {
                final freeAvatars = allAvatars.where((a) => a.tier == AvatarTier.free).toList();
                final premiumAvatars = allAvatars.where((a) => a.tier == AvatarTier.premium).toList();
                
                return isPremiumAsync.when(
                  data: (isPremium) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Free Avatars Section
                      _buildAvatarSection(
                        title: 'Free Avatars',
                        avatars: freeAvatars,
                        isPremium: true, // Always available
                        theme: theme,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Premium Avatars Section
                      _buildAvatarSection(
                        title: 'Premium Avatars',
                        avatars: premiumAvatars,
                        isPremium: isPremium,
                        theme: theme,
                        onUnlockTap: _unlockPremium,
                      ),
                    ],
                  ),
                  error: (_, __) => _buildErrorWidget('Failed to check premium status'),
                  loading: () => const Center(child: CircularProgressIndicator()),
                );
              },
              error: (_, __) => _buildErrorWidget('Failed to load avatars'),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            
            const SizedBox(height: 32),
            
            // Error Message
            if (_errorMessage != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.standardPadding),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (_errorMessage != null) const SizedBox(height: 16),
            
            // Save & Continue Button
            SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection({
    required String title,
    required List<Avatar> avatars,
    required bool isPremium,
    required ThemeData theme,
    VoidCallback? onUnlockTap,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.standardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isPremium && onUnlockTap != null)
                  TextButton.icon(
                    onPressed: onUnlockTap,
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('Unlock Premium'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final isSelected = _selectedAvatarKey == avatar.path;
                final isLocked = !isPremium && avatar.tier == AvatarTier.premium;
                
                return GestureDetector(
                  onTap: isLocked ? null : () {
                    setState(() {
                      _selectedAvatarKey = avatar.path;
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            avatar.path,
                            fit: BoxFit.cover,
                            color: isLocked ? Colors.grey : null,
                            colorBlendMode: isLocked ? BlendMode.saturation : null,
                          ),
                        ),
                        if (isLocked)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.standardPadding),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
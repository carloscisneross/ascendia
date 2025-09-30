import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants.dart';
import '../../../data/services/streak_service.dart';
import '../providers/avatar_providers.dart';
import 'widgets/check_in_section.dart';
import 'widgets/medals_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _changeAvatar() async {
    final result = await Navigator.of(context).pushNamed('/profileSetup');
    if (result == true) {
      // Avatar changed successfully, refresh providers if needed
      ref.invalidate(userProfileProvider);
    }
  }

  Future<void> _resetStreak() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Streak'),
        content: const Text(
          'Are you sure you want to reset your streak? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.resetStreak(
        user.uid,
        motive: 'Manual reset',
        note: 'Reset from profile screen',
      );

      // Refresh providers
      ref.invalidate(currentStreakProvider);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Streak reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to reset streak. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editGoal() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profileAsync = ref.read(userProfileProvider(user.uid));
    final currentGoal = await profileAsync.first.then((snapshot) {
      if (snapshot?.exists == true) {
        final data = snapshot!.data() as Map<String, dynamic>;
        return data['goalInDays'] ?? AppConstants.defaultStreakGoalDays;
      }
      return AppConstants.defaultStreakGoalDays;
    });

    if (!mounted) return;

    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => _GoalPickerDialog(currentGoal: currentGoal),
    );

    if (newGoal == null || newGoal == currentGoal) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.setStreakGoal(user.uid, newGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal updated to $newGoal days!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update goal. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final streakDays = ref.watch(currentStreakProvider);
    final isPremiumAsync = ref.watch(premiumStatusProvider);
    
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64),
              const SizedBox(height: 16),
              const Text('Not signed in'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (snapshot) {
          if (snapshot?.exists != true) {
            return const Center(child: Text('Profile not found'));
          }

          final data = snapshot!.data() as Map<String, dynamic>;
          final username = data['username'] ?? 'Ascender';
          final avatarKey = data['avatarKey'] ?? AppConstants.defaultFreeAvatarPath;
          final goalInDays = data['goalInDays'] ?? AppConstants.defaultStreakGoalDays;
          final isPremium = data['isPremium'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.standardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius - 2),
                            child: Image.asset(
                              avatarKey,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Username
                        Text(
                          username,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Premium Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPremium 
                                ? Colors.amber.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPremium ? Icons.workspace_premium : Icons.person,
                                size: 16,
                                color: isPremium ? Colors.amber[700] : null,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isPremium ? 'Premium' : 'Free',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isPremium ? Colors.amber[700] : null,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Daily Check-in Section
                const CheckInSection(),
                
                const SizedBox(height: 16),
                
                // Streak Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streak Progress',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Current Streak
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.local_fire_department,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$streakDays Days',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'Current Streak',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Goal Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Goal: $goalInDays days',
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              '${((streakDays / goalInDays) * 100).clamp(0, 100).toInt()}%',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Progress Bar
                        LinearProgressIndicator(
                          value: (streakDays / goalInDays).clamp(0.0, 1.0),
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Medals Section
                const MedalsSection(),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Change Avatar Button
                        SizedBox(
                          width: double.infinity,
                          height: AppConstants.buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _changeAvatar,
                            icon: const Icon(Icons.edit),
                            label: const Text('Change Avatar'),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Edit Goal Button
                        SizedBox(
                          width: double.infinity,
                          height: AppConstants.buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _editGoal,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Goal'),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Reset Streak Button
                        SizedBox(
                          width: double.infinity,
                          height: AppConstants.buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _resetStreak,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Streak'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Premium Button (if not premium)
                        if (!isPremium)
                          isPremiumAsync.when(
                            data: (isPremiumFromRC) {
                              if (!isPremiumFromRC) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: AppConstants.buttonHeight,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : () async {
                                      final result = await Navigator.of(context).pushNamed('/premium');
                                      if (result == true) {
                                        ref.invalidate(premiumStatusProvider);
                                        ref.invalidate(userProfileProvider);
                                      }
                                    },
                                    icon: const Icon(Icons.workspace_premium),
                                    label: const Text('Upgrade to Premium'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            error: (_, __) => const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
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
                ],
                
                // Loading Indicator
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64),
              const SizedBox(height: 16),
              Text('Failed to load profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userProfileProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _GoalPickerDialog extends StatefulWidget {
  final int currentGoal;

  const _GoalPickerDialog({required this.currentGoal});

  @override
  State<_GoalPickerDialog> createState() => _GoalPickerDialogState();
}

class _GoalPickerDialogState extends State<_GoalPickerDialog> {
  late int _selectedGoal;
  final List<int> _goalOptions = [7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal;
    // If current goal is not in options, add it
    if (!_goalOptions.contains(_selectedGoal)) {
      _goalOptions.add(_selectedGoal);
      _goalOptions.sort();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Set Your Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose your streak goal:'),
          const SizedBox(height: 16),
          ..._goalOptions.map((goal) {
            return RadioListTile<int>(
              title: Text('$goal days'),
              value: goal,
              groupValue: _selectedGoal,
              onChanged: (value) {
                setState(() {
                  _selectedGoal = value!;
                });
              },
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedGoal),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

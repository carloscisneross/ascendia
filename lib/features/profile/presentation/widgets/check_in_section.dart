import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/providers.dart';
import '../providers/streak_medal_providers.dart';

class CheckInSection extends ConsumerStatefulWidget {
  const CheckInSection({super.key});

  @override
  ConsumerState<CheckInSection> createState() => _CheckInSectionState();
}

class _CheckInSectionState extends ConsumerState<CheckInSection> with TickerProviderStateMixin {
  bool _isCheckingIn = false;
  String? _checkInMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performCheckIn() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isCheckingIn = true;
      _checkInMessage = null;
    });

    try {
      final streakService = ref.read(enhancedStreakServiceProvider);
      final result = await streakService.performCheckIn(user.uid);

      if (result.success) {
        // Trigger celebration animation
        _animationController.forward().then((_) {
          _animationController.reverse();
        });

        // Refresh providers to show updated data
        ref.invalidate(currentStreakProvider);
        ref.invalidate(streakStatusProvider);
        ref.invalidate(earnedMedalsProvider);
        ref.invalidate(nextMedalProvider);

        setState(() {
          _checkInMessage = result.message;
        });

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.isNewRecord ? Colors.amber : Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _checkInMessage = result.message;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _checkInMessage = 'Failed to check in. Please try again.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isCheckingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final streakStatusAsync = ref.watch(streakStatusProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: streakStatusAsync.when(
          data: (status) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Daily Check-in',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Status Display
                if (status.streakAtRisk) ...[
                  _StreakAtRiskWidget(),
                ] else if (status.hasCheckedInToday) ...[
                  _AlreadyCheckedInWidget(),
                ] else if (status.canCheckInToday) ...[
                  _CanCheckInWidget(
                    onCheckIn: _performCheckIn,
                    isLoading: _isCheckingIn,
                    animationController: _animationController,
                    scaleAnimation: _scaleAnimation,
                  ),
                ] else ...[
                  _CannotCheckInWidget(),
                ],
                
                // Check-in Message
                if (_checkInMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _checkInMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Last Check-in Info
                if (status.lastCheckIn != null)
                  Text(
                    'Last check-in: ${_formatLastCheckIn(status.lastCheckIn!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            );
          },
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load check-in status',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(streakStatusProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastCheckIn(DateTime lastCheckIn) {
    final now = DateTime.now();
    final difference = now.difference(lastCheckIn);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

class _CanCheckInWidget extends StatelessWidget {
  final VoidCallback onCheckIn;
  final bool isLoading;
  final AnimationController animationController;
  final Animation<double> scaleAnimation;

  const _CanCheckInWidget({
    required this.onCheckIn,
    required this.isLoading,
    required this.animationController,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        AnimatedBuilder(
          animation: scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check,
                  color: theme.colorScheme.onPrimary,
                  size: 32,
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Ready for today\'s check-in!',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Tap the button to continue your streak',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 20),
        
        SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onCheckIn,
            icon: isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.local_fire_department),
            label: Text(isLoading ? 'Checking in...' : 'Check In'),
          ),
        ),
      ],
    );
  }
}

class _AlreadyCheckedInWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 32,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Already checked in today!',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Great job keeping up your streak!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StreakAtRiskWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning,
            color: theme.colorScheme.onError,
            size: 32,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Streak has been reset',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'You missed a day, but don\'t give up! Start a new streak today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CannotCheckInWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.schedule,
            color: theme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Check-in not available',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Come back tomorrow to continue your streak!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
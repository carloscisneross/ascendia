import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../data/models/models.dart';
import '../providers/streak_medal_providers.dart';

class MedalsSection extends ConsumerWidget {
  const MedalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final earnedMedalsAsync = ref.watch(earnedMedalsProvider);
    final personalMedalsAsync = ref.watch(personalMedalsProvider);
    final nextMedalAsync = ref.watch(nextMedalProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Medals',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Next Medal Progress
            nextMedalAsync.when(
              data: (nextMedal) {
                if (nextMedal != null) {
                  return _NextMedalWidget(medal: nextMedal);
                } else {
                  return _AllMedalsEarnedWidget();
                }
              },
              error: (_, __) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 20),
            
            // Medals Grid
            personalMedalsAsync.when(
              data: (allMedals) {
                return earnedMedalsAsync.when(
                  data: (earnedMedals) {
                    return _MedalsGrid(
                      allMedals: allMedals,
                      earnedMedals: earnedMedals,
                    );
                  },
                  error: (error, _) => _ErrorWidget(message: 'Failed to load earned medals: $error'),
                  loading: () => const Center(child: CircularProgressIndicator()),
                );
              },
              error: (error, _) => _ErrorWidget(message: 'Failed to load medals: $error'),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextMedalWidget extends ConsumerWidget {
  final MedalSpec medal;

  const _NextMedalWidget({required this.medal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streakDays = ref.watch(currentStreakProvider);
    final requiredDays = medal.durationDays ?? 0;
    final progress = streakDays / requiredDays;
    final daysLeft = requiredDays - streakDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Medal Image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    medal.normalAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.emoji_events,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Medal Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next: ${medal.name}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daysLeft days to go',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$streakDays / $requiredDays days',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${(progress * 100).clamp(0, 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllMedalsEarnedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            color: Colors.amber[700],
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legend Status!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve earned all available medals!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalsGrid extends StatelessWidget {
  final List<MedalSpec> allMedals;
  final List<MedalSpec> earnedMedals;

  const _MedalsGrid({
    required this.allMedals,
    required this.earnedMedals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: allMedals.length > 8 ? 8 : allMedals.length, // Show first 8
          itemBuilder: (context, index) {
            final medal = allMedals[index];
            final isEarned = earnedMedals.any((earned) => earned.id == medal.id);
            
            return _MedalItem(
              medal: medal,
              isEarned: isEarned,
            );
          },
        ),
      ],
    );
  }
}

class _MedalItem extends StatelessWidget {
  final MedalSpec medal;
  final bool isEarned;

  const _MedalItem({
    required this.medal,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isEarned 
                ? Colors.transparent
                : theme.colorScheme.surfaceVariant,
            border: Border.all(
              color: isEarned 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isEarned ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              medal.normalAssetPath,
              fit: BoxFit.cover,
              color: isEarned ? null : Colors.grey,
              colorBlendMode: isEarned ? null : BlendMode.saturation,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.emoji_events,
                    color: isEarned 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          medal.name,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
            color: isEarned 
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
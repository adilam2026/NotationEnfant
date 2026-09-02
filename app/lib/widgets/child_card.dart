import 'package:flutter/material.dart';

import '../data/avatars.dart';
import '../models/child.dart';
import '../models/reward.dart';
import '../theme/app_colors.dart';
import 'star_progress_bar.dart';

/// Big, visual card for a child on the parent home screen. No ranking, no
/// comparison with siblings — just this child's own progress.
class ChildCard extends StatelessWidget {
  final Child child;
  final List<Reward> rewards;
  final VoidCallback onTap;

  const ChildCard({
    super.key,
    required this.child,
    required this.rewards,
    required this.onTap,
  });

  Reward? get _nextReward {
    final locked = rewards
        .where((r) => r.starsRequired > child.availableStars)
        .toList()
      ..sort((a, b) => a.starsRequired.compareTo(b.starsRequired));
    return locked.isEmpty ? null : locked.first;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.themeColorDark(child.theme);
    final next = _nextReward;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.themeColor(child.theme),
                  shape: BoxShape.circle,
                ),
                child: Text(avatarEmoji(child.avatar),
                    style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.firstName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${child.availableStars}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (next != null) ...[
                      StarProgressBar(
                        current: child.availableStars,
                        target: next.starsRequired,
                        color: color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🎁 Prochaine récompense : ${next.title}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else if (rewards.isNotEmpty)
                      const Text(
                        '🎉 Toutes les récompenses sont débloquées !',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

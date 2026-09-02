import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/avatars.dart';
import '../../models/child.dart';
import '../../models/reward.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../root/root_shell.dart';
import 'add_edit_reward_screen.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '🎁 Mes récompenses',
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppColors.mintDark, size: 32),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddEditRewardScreen()),
            ),
          ),
        ),
        if (family.isOffline) const OfflineBanner(),
        if (!family.isOffline && family.errorMessage != null)
          ErrorBanner(message: family.errorMessage!, onRetry: family.refresh),
        Expanded(
          child: family.rewards.isEmpty
              ? EmptyState(
                  emoji: '🎁',
                  title: 'Aucune récompense',
                  actionLabel: 'Créer une récompense',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddEditRewardScreen()),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.mintDark,
                  onRefresh: family.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: family.rewards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => _RewardCard(reward: family.rewards[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;

  const _RewardCard({required this.reward});

  Future<void> _redeem(BuildContext context, Child child) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '🎉 Bravo !',
      message:
          'Utiliser ${reward.starsRequired} ⭐ de ${child.firstName} pour "${reward.title}" ?',
      confirmLabel: '🎁 Utiliser mes étoiles',
      destructive: false,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<FamilyProvider>().redeemReward(
            childId: child.id,
            rewardId: reward.id,
          );
      if (context.mounted) {
        showCelebration(
          context,
          emoji: reward.emoji,
          message: '🎉 ${child.firstName} a débloqué\n${reward.title} !',
          intense: true,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(reward.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reward.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text('${reward.starsRequired} ⭐',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.starDark)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditRewardScreen(existing: reward),
                    ),
                  ),
                ),
              ],
            ),
            if (family.children.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: family.children.map((child) {
                  final unlocked = child.availableStars >= reward.starsRequired;
                  return GestureDetector(
                    onTap: unlocked ? () => _redeem(context, child) : null,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? AppColors.mint.withValues(alpha: 0.6)
                            : const Color(0xFFF3F1EC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(avatarEmoji(child.avatar),
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            unlocked
                                ? '${child.firstName} 🎁'
                                : '${child.firstName} · encore ${reward.starsRequired - child.availableStars} ⭐',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: unlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

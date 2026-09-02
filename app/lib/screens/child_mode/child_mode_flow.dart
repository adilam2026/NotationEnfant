import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/avatars.dart';
import '../../models/child.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pin_entry_dialog.dart';
import '../../widgets/star_progress_bar.dart';

/// Read-only view shown while "Mode enfant" is active: no rating buttons,
/// just the child's own progress. Exiting requires the 4-digit parent PIN.
class ChildModeFlow extends StatefulWidget {
  const ChildModeFlow({super.key});

  @override
  State<ChildModeFlow> createState() => _ChildModeFlowState();
}

class _ChildModeFlowState extends State<ChildModeFlow> {
  int _selected = 0;

  Future<void> _tryExit(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final childMode = context.read<ChildModeProvider>();
    String? error;
    while (true) {
      final pin = await showPinEntryDialog(context, errorText: error);
      if (pin == null || !context.mounted) return;
      final ok = childMode.tryExit(pin, auth.profile?.parentPin);
      if (ok) return;
      error = 'Code incorrect';
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final children = family.children;

    if (children.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _lockBar(context),
              const Expanded(
                child: Center(child: Text('🌱', style: TextStyle(fontSize: 48))),
              ),
            ],
          ),
        ),
      );
    }

    final index = _selected.clamp(0, children.length - 1);
    final child = children[index];
    final color = AppColors.themeColorDark(child.theme);
    final locked = family.rewards
        .where((r) => r.starsRequired > child.availableStars)
        .toList()
      ..sort((a, b) => a.starsRequired.compareTo(b.starsRequired));
    final nextReward = locked.isEmpty ? null : locked.first;
    final todayStars = family.starsGainedToday(child.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _lockBar(context),
            if (children.length > 1) _childSwitcher(children, index),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.themeColor(child.theme),
                        shape: BoxShape.circle,
                      ),
                      child: Text(avatarEmoji(child.avatar),
                          style: const TextStyle(fontSize: 76)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      child.firstName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('🌟', style: TextStyle(fontSize: 40)),
                    Text(
                      '${child.availableStars}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'ÉTOILES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (nextReward != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Text(
                              nextReward.starsRequired - child.availableStars <= 0
                                  ? '🎉 Récompense débloquée !'
                                  : '🎁 Plus que ${nextReward.starsRequired - child.availableStars} ⭐',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'pour ${nextReward.emoji} ${nextReward.title}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StarProgressBar(
                              current: child.availableStars,
                              target: nextReward.starsRequired,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),
                    Text(
                      'Aujourd\'hui',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      todayStars > 0 ? '⭐' * todayStars.clamp(0, 10) : '—',
                      style: const TextStyle(fontSize: 20),
                    ),
                    if (todayStars > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$todayStars étoile${todayStars > 1 ? 's' : ''} gagnée${todayStars > 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          icon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
          onPressed: () => _tryExit(context),
        ),
      ),
    );
  }

  Widget _childSwitcher(List<Child> children, int index) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = children[i];
          final selected = i == index;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: selected
                  ? AppColors.themeColorDark(c.theme)
                  : AppColors.themeColor(c.theme),
              child: Text(avatarEmoji(c.avatar), style: const TextStyle(fontSize: 22)),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/avatars.dart';
import '../../data/celebrations.dart';
import '../../data/reasons.dart';
import '../../models/star_event.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/badges.dart';
import '../../utils/star_logic.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/star_progress_bar.dart';
import '../../widgets/undo_snackbar.dart';
import '../../widgets/week_bubbles.dart';
import '../rating/reason_picker_sheet.dart';
import 'add_edit_child_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final String childId;

  const ChildDetailScreen({super.key, required this.childId});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  bool _busy = false;
  final _shownBadges = <String>{};
  final _random = Random();

  Future<void> _rate(int value, EventCategory category, List<ReasonOption> options,
      {required String title, required Color accent}) async {
    if (_busy) return;
    final reason = await showReasonPicker(
      context,
      title: title,
      options: options,
      accent: accent,
    );
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    final family = context.read<FamilyProvider>();
    try {
      final event = await family.rateChild(
        childId: widget.childId,
        value: value,
        category: category,
        reason: reason.key,
      );
      if (!mounted) return;
      _celebrate(value);
      final child = family.childById(widget.childId);
      showUndoSnackbar(
        context,
        message: '${value > 0 ? '+' : ''}$value ⭐ ${value >= 0 ? 'ajouté' : 'retiré'} '
            'à ${child?.firstName ?? ''}',
        onUndo: () => family.undoEvent(event.id),
      );
      _maybeShowBadge(family);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _celebrate(int value) {
    if (value < 0) {
      showCelebration(
        context,
        emoji: '😕',
        message: 'Oups…\n$kEncouragementMessage',
        negative: true,
      );
      return;
    }
    final message = kCelebrationMessages[_random.nextInt(kCelebrationMessages.length)];
    showCelebration(
      context,
      emoji: value == 2 ? '🌟🌟' : '⭐',
      message: message,
      intense: value == 2,
    );
  }

  void _maybeShowBadge(FamilyProvider family) {
    final today = eventsOn(family.eventsForChild(widget.childId), DateTime.now());
    final badges = badgesForToday(today);
    for (final badge in badges) {
      if (_shownBadges.add(badge.label)) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${badge.emoji} Badge : ${badge.label}')),
          );
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final child = family.childById(widget.childId);

    if (child == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final color = AppColors.themeColorDark(child.theme);
    final events = family.eventsForChild(child.id);
    final locked = family.rewards
        .where((r) => r.starsRequired > child.availableStars)
        .toList()
      ..sort((a, b) => a.starsRequired.compareTo(b.starsRequired));
    final nextReward = locked.isEmpty ? null : locked.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(child.firstName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditChildScreen(existing: child),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.themeColor(child.theme),
                      shape: BoxShape.circle,
                    ),
                    child: Text(avatarEmoji(child.avatar),
                        style: const TextStyle(fontSize: 52)),
                  ),
                  const SizedBox(height: 14),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, scale, childWidget) =>
                        Transform.scale(scale: scale, child: childWidget),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 6),
                        Text(
                          '${child.availableStars}',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _RatingButton(
                    emoji: '😕',
                    label: '−1',
                    color: AppColors.softRed,
                    onTap: () => _rate(-1, EventCategory.negative, kNegativeReasons,
                        title: '😕 Oups…', accent: AppColors.softRedDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RatingButton(
                    emoji: '😊',
                    label: '+1',
                    color: AppColors.mint,
                    onTap: () => _rate(1, EventCategory.positive, kPositiveReasons,
                        title: '😊 Belle action !', accent: AppColors.mintDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RatingButton(
                    emoji: '🌟',
                    label: '+2',
                    color: AppColors.star,
                    onTap: () => _rate(2, EventCategory.exceptional, kExceptionalReasons,
                        title: '🌟 Waouh !', accent: AppColors.starDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatBlock(
                          label: 'Cette semaine',
                          value: '+${family.starsGainedThisWeek(child.id)} ⭐',
                        ),
                        _StatBlock(
                          label: 'Total disponible',
                          value: '${child.availableStars} ⭐',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    WeekBubbles(events: events),
                  ],
                ),
              ),
            ),
            if (nextReward != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎁 Prochaine récompense : ${nextReward.title}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

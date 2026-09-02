import 'package:flutter/material.dart';

import '../models/star_event.dart';
import '../theme/app_colors.dart';
import '../utils/star_logic.dart';

const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Seven small bubbles representing the current week — a glanceable
/// alternative to a spreadsheet-style table.
class WeekBubbles extends StatelessWidget {
  final List<StarEvent> events;

  const WeekBubbles({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final monday = startOfWeek(DateTime.now());
    final counts = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return starsGainedSince(events, day) -
          starsGainedSince(events, day.add(const Duration(days: 1)));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final count = counts[i].clamp(0, 9);
        final isToday = startOfDay(DateTime.now()) == monday.add(Duration(days: i));
        return Column(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count > 0
                    ? AppColors.star.withValues(alpha: 0.9)
                    : const Color(0xFFF1EFEA),
                border: isToday
                    ? Border.all(color: AppColors.mintDark, width: 2)
                    : null,
              ),
              child: Text(
                count > 0 ? '$count' : '—',
                style: TextStyle(
                  fontSize: count > 0 ? 13 : 11,
                  fontWeight: FontWeight.w800,
                  color: count > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _dayLabels[i],
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        );
      }),
    );
  }
}

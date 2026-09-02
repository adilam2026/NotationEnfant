import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/avatars.dart';
import '../../data/reasons.dart';
import '../../models/star_event.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/reason_lookup.dart';
import '../../utils/star_logic.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../rating/reason_picker_sheet.dart';
import '../root/root_shell.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  List<ReasonOption> _reasonsFor(EventCategory category) {
    switch (category) {
      case EventCategory.positive:
        return kPositiveReasons;
      case EventCategory.exceptional:
        return kExceptionalReasons;
      case EventCategory.negative:
        return kNegativeReasons;
      case EventCategory.rewardRedeemed:
        return [];
    }
  }

  Future<void> _openActions(BuildContext context, StarEvent event) async {
    final family = context.read<FamilyProvider>();
    final canEditReason = event.category != EventCategory.rewardRedeemed;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            if (canEditReason)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier le motif'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.softRedDark),
              title: const Text('Supprimer',
                  style: TextStyle(color: AppColors.softRedDark)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'delete') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Supprimer cet événement ?',
        message: 'Le solde d\'étoiles sera recalculé automatiquement.',
      );
      if (confirmed) await family.deleteEvent(event);
    } else if (action == 'edit') {
      final newReason = await showReasonPicker(
        context,
        title: 'Nouveau motif',
        options: _reasonsFor(event.category),
        accent: AppColors.mintDark,
      );
      if (newReason != null) {
        await family.updateEvent(event, reason: newReason.key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final events = family.recentEvents;
    final showChildName = family.children.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '📅 Historique'),
        if (family.isOffline) const OfflineBanner(),
        if (!family.isOffline && family.errorMessage != null)
          ErrorBanner(message: family.errorMessage!, onRetry: family.refresh),
        Expanded(
          child: events.isEmpty
              ? const EmptyState(
                  emoji: '🌱',
                  title: 'L\'aventure commence !',
                  subtitle: 'Les premières étoiles apparaîtront ici.',
                )
              : RefreshIndicator(
                  color: AppColors.mintDark,
                  onRefresh: family.refresh,
                  child: _GroupedList(
                    events: events,
                    showChildName: showChildName,
                    childName: (id) => family.childById(id)?.firstName ?? '',
                    childAvatar: (id) => family.childById(id)?.avatar ?? 'lion',
                    onTap: (e) => _openActions(context, e),
                  ),
                ),
        ),
      ],
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<StarEvent> events;
  final bool showChildName;
  final String Function(String childId) childName;
  final String Function(String childId) childAvatar;
  final void Function(StarEvent) onTap;

  const _GroupedList({
    required this.events,
    required this.showChildName,
    required this.childName,
    required this.childAvatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<StarEvent>>{};
    for (final e in events) {
      final key = _dayLabel(e.createdAt);
      groups.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: groups.entries.expand((entry) {
        final total = entry.value.fold(0, (sum, e) => sum + e.value);
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${total >= 0 ? '+' : ''}$total ⭐ au total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map((e) => _EventTile(
                event: e,
                showChildName: showChildName,
                childLabel: childName(e.childId),
                avatar: childAvatar(e.childId),
                onTap: () => onTap(e),
              )),
        ];
      }).toList(),
    );
  }

  static const _weekdays = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
    'septembre', 'octobre', 'novembre', 'décembre'
  ];

  String _dayLabel(DateTime date) {
    final today = startOfDay(DateTime.now());
    final day = startOfDay(date);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    return '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
  }
}

class _EventTile extends StatelessWidget {
  final StarEvent event;
  final bool showChildName;
  final String childLabel;
  final String avatar;
  final VoidCallback onTap;

  const _EventTile({
    required this.event,
    required this.showChildName,
    required this.childLabel,
    required this.avatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final positive = event.value >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Text(eventEmoji(event), style: const TextStyle(fontSize: 24)),
        title: Text(
          reasonLabel(event),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: showChildName
            ? Text('${avatarEmoji(avatar)} $childLabel',
                style: const TextStyle(fontSize: 12))
            : null,
        trailing: Text(
          '${positive ? '+' : ''}${event.value} ⭐',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: positive ? AppColors.mintDark : AppColors.softRedDark,
          ),
        ),
      ),
    );
  }
}

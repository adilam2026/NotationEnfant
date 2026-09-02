import '../models/star_event.dart';

class AppBadge {
  final String emoji;
  final String label;
  const AppBadge(this.emoji, this.label);
}

const _shareReasons = {'partage'};
const _tidyReasons = {'rangement', 'pas_range'};
const _effortReasons = {'effort', 'gros_effort'};

/// Small, optional badges computed on the fly from today's events for a
/// child — no extra table needed, no levels, no XP, just a fun surprise.
List<AppBadge> badgesForToday(List<StarEvent> childEventsToday) {
  final badges = <AppBadge>[];

  final gainedToday = childEventsToday
      .where((e) => e.value > 0)
      .fold(0, (sum, e) => sum + e.value);
  if (gainedToday >= 5) {
    badges.add(const AppBadge('🌟', '5 étoiles en une journée'));
  }

  final niceActions =
      childEventsToday.where((e) => e.category != EventCategory.negative).length;
  if (niceActions >= 3) {
    badges.add(const AppBadge('❤️', '3 belles actions'));
  }

  if (childEventsToday.any((e) => _effortReasons.contains(e.reason))) {
    badges.add(const AppBadge('💪', 'Super effort'));
  }
  if (childEventsToday.any((e) => _shareReasons.contains(e.reason))) {
    badges.add(const AppBadge('🤝', 'Champion du partage'));
  }
  if (childEventsToday.any((e) =>
      _tidyReasons.contains(e.reason) && e.category != EventCategory.negative)) {
    badges.add(const AppBadge('🧸', 'Champion du rangement'));
  }

  return badges;
}

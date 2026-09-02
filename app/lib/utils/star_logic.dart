import '../models/star_event.dart';

/// Applies the same "never below zero" clamp the database trigger uses,
/// so optimistic UI updates match what the server will settle on.
int applyClampedEvent(int currentStars, int eventValue) {
  final next = currentStars + eventValue;
  return next < 0 ? 0 : next;
}

/// Sum of positive event values gained since [since] (used for "cette
/// semaine" and "aujourd'hui" counters). Negative events still count
/// towards history but are excluded from "gained" totals.
int starsGainedSince(List<StarEvent> events, DateTime since) {
  return events
      .where((e) => e.createdAt.isAfter(since) && e.value > 0)
      .fold(0, (sum, e) => sum + e.value);
}

List<StarEvent> eventsOn(List<StarEvent> events, DateTime day) {
  return events.where((e) {
    final d = e.createdAt;
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }).toList();
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek(DateTime d) {
  final day = startOfDay(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

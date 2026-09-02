import 'package:flutter_test/flutter_test.dart';
import 'package:mes_etoiles/models/star_event.dart';
import 'package:mes_etoiles/utils/badges.dart';

StarEvent _event(int value, EventCategory category, String reason) {
  return StarEvent(
    id: 'e',
    childId: 'c',
    value: value,
    category: category,
    reason: reason,
    createdAt: DateTime.now(),
  );
}

void main() {
  test('no badges for an empty day', () {
    expect(badgesForToday([]), isEmpty);
  });

  test('5 stars in a day unlocks the daily badge', () {
    final events = [
      _event(2, EventCategory.exceptional, 'grosse_aide'),
      _event(2, EventCategory.exceptional, 'gros_effort'),
      _event(1, EventCategory.positive, 'rangement'),
    ];
    final badges = badgesForToday(events);
    expect(badges.any((b) => b.label == '5 étoiles en une journée'), isTrue);
  });

  test('sharing reason unlocks the sharing badge', () {
    final badges = badgesForToday([_event(1, EventCategory.positive, 'partage')]);
    expect(badges.any((b) => b.label == 'Champion du partage'), isTrue);
  });

  test('a negative-only day unlocks no positive badges', () {
    final badges = badgesForToday([_event(-1, EventCategory.negative, 'colere')]);
    expect(badges, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mes_etoiles/models/star_event.dart';
import 'package:mes_etoiles/utils/star_logic.dart';

void main() {
  group('applyClampedEvent', () {
    test('never goes below zero', () {
      expect(applyClampedEvent(0, -1), 0);
    });

    test('a blocked negative event does not eat into a later gain', () {
      // Rule 20 of the spec: 0 stars, -1 (blocked, stays 0), then +1 -> 1,
      // not 0. Each event is clamped as it is applied, not summed first.
      var stars = 0;
      stars = applyClampedEvent(stars, -1);
      expect(stars, 0);
      stars = applyClampedEvent(stars, 1);
      expect(stars, 1);
    });

    test('adds positive values normally', () {
      expect(applyClampedEvent(5, 1), 6);
      expect(applyClampedEvent(5, 2), 7);
    });

    test('subtracts without going negative', () {
      expect(applyClampedEvent(1, -1), 0);
      expect(applyClampedEvent(3, -1), 2);
    });

    test('reward redemption can spend the full balance down to zero', () {
      expect(applyClampedEvent(20, -20), 0);
    });
  });

  group('starsGainedSince', () {
    test('only counts positive events after the cutoff', () {
      final now = DateTime(2026, 1, 10, 12);
      final events = [
        StarEvent(
            id: '1',
            childId: 'c',
            value: 1,
            category: EventCategory.positive,
            reason: 'x',
            createdAt: now),
        StarEvent(
            id: '2',
            childId: 'c',
            value: -1,
            category: EventCategory.negative,
            reason: 'x',
            createdAt: now),
        StarEvent(
            id: '3',
            childId: 'c',
            value: 2,
            category: EventCategory.exceptional,
            reason: 'x',
            createdAt: now.subtract(const Duration(days: 10))),
      ];
      final gained = starsGainedSince(events, DateTime(2026, 1, 1));
      expect(gained, 1); // only event "1" is after the cutoff and positive
    });
  });
}

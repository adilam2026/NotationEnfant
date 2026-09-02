import '../data/reasons.dart';
import '../models/star_event.dart';

String reasonLabel(StarEvent event) {
  if (event.category == EventCategory.rewardRedeemed) {
    return event.reason;
  }
  final all = [...kPositiveReasons, ...kExceptionalReasons, ...kNegativeReasons];
  for (final r in all) {
    if (r.key == event.reason) return r.label;
  }
  return event.reason;
}

String eventEmoji(StarEvent event) {
  switch (event.category) {
    case EventCategory.positive:
      return '😊';
    case EventCategory.exceptional:
      return '🌟';
    case EventCategory.negative:
      return '😕';
    case EventCategory.rewardRedeemed:
      return '🎁';
  }
}

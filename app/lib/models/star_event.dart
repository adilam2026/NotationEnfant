enum EventCategory { positive, negative, exceptional, rewardRedeemed }

EventCategory categoryFromString(String value) {
  switch (value) {
    case 'positive':
      return EventCategory.positive;
    case 'negative':
      return EventCategory.negative;
    case 'exceptional':
      return EventCategory.exceptional;
    case 'reward_redeemed':
      return EventCategory.rewardRedeemed;
    default:
      return EventCategory.positive;
  }
}

String categoryToString(EventCategory category) {
  switch (category) {
    case EventCategory.positive:
      return 'positive';
    case EventCategory.negative:
      return 'negative';
    case EventCategory.exceptional:
      return 'exceptional';
    case EventCategory.rewardRedeemed:
      return 'reward_redeemed';
  }
}

class StarEvent {
  final String id;
  final String childId;
  final int value;
  final EventCategory category;
  final String reason;
  final DateTime createdAt;

  const StarEvent({
    required this.id,
    required this.childId,
    required this.value,
    required this.category,
    required this.reason,
    required this.createdAt,
  });

  factory StarEvent.fromMap(Map<String, dynamic> map) {
    return StarEvent(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      value: (map['value'] as num).toInt(),
      category: categoryFromString(map['category'] as String),
      reason: map['reason'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

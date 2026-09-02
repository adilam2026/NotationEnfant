class Reward {
  final String id;
  final String profileId;
  final String title;
  final String emoji;
  final int starsRequired;
  final bool active;
  final DateTime createdAt;

  const Reward({
    required this.id,
    required this.profileId,
    required this.title,
    required this.emoji,
    required this.starsRequired,
    required this.active,
    required this.createdAt,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      title: map['title'] as String,
      emoji: map['emoji'] as String? ?? '🎁',
      starsRequired: (map['stars_required'] as num).toInt(),
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class RedeemedReward {
  final String id;
  final String childId;
  final String? rewardId;
  final int starsSpent;
  final DateTime createdAt;

  const RedeemedReward({
    required this.id,
    required this.childId,
    required this.rewardId,
    required this.starsSpent,
    required this.createdAt,
  });

  factory RedeemedReward.fromMap(Map<String, dynamic> map) {
    return RedeemedReward(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      rewardId: map['reward_id'] as String?,
      starsSpent: (map['stars_spent'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

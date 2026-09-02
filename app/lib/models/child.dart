class Child {
  final String id;
  final String profileId;
  final String firstName;
  final String avatar;
  final String theme;
  final int availableStars;
  final DateTime createdAt;

  const Child({
    required this.id,
    required this.profileId,
    required this.firstName,
    required this.avatar,
    required this.theme,
    required this.availableStars,
    required this.createdAt,
  });

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      firstName: map['first_name'] as String,
      avatar: map['avatar'] as String? ?? 'lion',
      theme: map['theme'] as String? ?? 'mint',
      availableStars: (map['available_stars'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'first_name': firstName,
      'avatar': avatar,
      'theme': theme,
      'available_stars': availableStars,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Child copyWith({
    String? firstName,
    String? avatar,
    String? theme,
    int? availableStars,
  }) {
    return Child(
      id: id,
      profileId: profileId,
      firstName: firstName ?? this.firstName,
      avatar: avatar ?? this.avatar,
      theme: theme ?? this.theme,
      availableStars: availableStars ?? this.availableStars,
      createdAt: createdAt,
    );
  }
}

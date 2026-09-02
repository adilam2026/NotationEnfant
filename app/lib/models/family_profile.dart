class FamilyProfile {
  final String id;
  final String email;
  final String familyName;
  final String? parentPin;
  final DateTime createdAt;

  const FamilyProfile({
    required this.id,
    required this.email,
    required this.familyName,
    required this.parentPin,
    required this.createdAt,
  });

  factory FamilyProfile.fromMap(Map<String, dynamic> map) {
    return FamilyProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      familyName: map['family_name'] as String? ?? 'Ma famille',
      parentPin: map['parent_pin'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FamilyProfile copyWith({String? familyName, String? parentPin}) {
    return FamilyProfile(
      id: id,
      email: email,
      familyName: familyName ?? this.familyName,
      parentPin: parentPin ?? this.parentPin,
      createdAt: createdAt,
    );
  }
}

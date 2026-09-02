class AvatarOption {
  final String key;
  final String emoji;

  const AvatarOption(this.key, this.emoji);
}

/// ~20 avatars: friendly cartoon-style kids + a few animal favorites,
/// expressed as emojis to avoid shipping custom art assets.
const List<AvatarOption> kAvatars = [
  AvatarOption('boy_dark_hair', '👦🏻'),
  AvatarOption('girl_dark_hair', '👧🏻'),
  AvatarOption('boy_curly', '👦🏽'),
  AvatarOption('girl_curly', '👧🏽'),
  AvatarOption('boy_glasses', '🧒'),
  AvatarOption('girl_glasses', '👧'),
  AvatarOption('boy_light_hair', '👦🏼'),
  AvatarOption('girl_light_hair', '👧🏼'),
  AvatarOption('boy_dark_skin', '👦🏿'),
  AvatarOption('girl_dark_skin', '👧🏿'),
  AvatarOption('baby', '🧒🏻'),
  AvatarOption('superhero', '🦸'),
  AvatarOption('lion', '🦁'),
  AvatarOption('panda', '🐼'),
  AvatarOption('fox', '🦊'),
  AvatarOption('koala', '🐨'),
  AvatarOption('tiger', '🐯'),
  AvatarOption('rabbit', '🐰'),
  AvatarOption('unicorn', '🦄'),
  AvatarOption('bear', '🐻'),
];

String avatarEmoji(String key) {
  return kAvatars
      .firstWhere(
        (a) => a.key == key,
        orElse: () => kAvatars.first,
      )
      .emoji;
}

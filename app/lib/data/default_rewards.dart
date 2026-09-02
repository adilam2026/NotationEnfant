class DefaultReward {
  final String title;
  final String emoji;
  final int starsRequired;

  const DefaultReward(this.title, this.emoji, this.starsRequired);
}

const List<DefaultReward> kDefaultRewards = [
  DefaultReward('Choisir le film', '🍿', 20),
  DefaultReward('Choisir le dessert', '🍰', 20),
  DefaultReward('30 min de jeu supplémentaire', '🎮', 30),
  DefaultReward('Choisir l\'activité familiale', '🎨', 40),
  DefaultReward('Petite surprise', '🎁', 50),
  DefaultReward('Sortie spéciale', '🌳', 70),
];

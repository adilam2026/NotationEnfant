class ReasonOption {
  final String key;
  final String emoji;
  final String label;

  const ReasonOption(this.key, this.emoji, this.label);

  String get display => '$emoji $label';
}

/// Motifs shown when the parent taps +1 (belle action).
const List<ReasonOption> kPositiveReasons = [
  ReasonOption('rangement', '🧸', 'A rangé'),
  ReasonOption('partage', '🤝', 'A partagé'),
  ReasonOption('ecoute', '👂', 'A écouté'),
  ReasonOption('aide', '❤️', 'A aidé'),
  ReasonOption('repas', '🍽️', 'A bien mangé'),
  ReasonOption('autonomie', '🪥', 'S\'est préparé seul'),
  ReasonOption('gentillesse', '🗣️', 'A parlé gentiment'),
  ReasonOption('effort', '📚', 'A fait un effort'),
  ReasonOption('reparation', '❤️', 'A réparé sa bêtise'),
  ReasonOption('autre_positif', '✨', 'Autre'),
];

/// Motifs shown when the parent taps +2 (action exceptionnelle).
const List<ReasonOption> kExceptionalReasons = [
  ReasonOption('grosse_aide', '❤️', 'A beaucoup aidé'),
  ReasonOption('belle_attention', '🤝', 'Très belle attention'),
  ReasonOption('gros_effort', '💪', 'Gros effort'),
  ReasonOption('difficulte', '🧠', 'A dépassé une difficulté'),
  ReasonOption('initiative', '🧸', 'Initiative spontanée'),
  ReasonOption('beau_comportement', '🥰', 'Très beau comportement'),
  ReasonOption('autre_exceptionnel', '✨', 'Autre'),
];

/// Motifs shown when the parent taps -1 (oups).
const List<ReasonOption> kNegativeReasons = [
  ReasonOption('pas_ecoute', '👂', 'N\'a pas écouté'),
  ReasonOption('mal_parle', '🗣️', 'A mal parlé'),
  ReasonOption('tape', '👊', 'A tapé / poussé'),
  ReasonOption('pas_range', '🧸', 'N\'a pas rangé'),
  ReasonOption('colere', '😡', 'Grosse colère'),
  ReasonOption('irrespect', '🤝', 'N\'a pas respecté l\'autre'),
  ReasonOption('autre_negatif', '✨', 'Autre'),
];

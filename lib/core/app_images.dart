/// Images intégrées à l'app, issues du brand kit (`docs/design/charte-graphique.md` §8).
abstract final class AppImages {
  static const mascot = 'assets/images/mascot.png';
  static const iconBook = 'assets/images/icon_book.png';
  static const iconPlay = 'assets/images/icon_play.png';
  static const iconHeart = 'assets/images/icon_heart.png';
  static const iconCrown = 'assets/images/icon_crown.png';
  static const iconFamily = 'assets/images/icon_family.png';

  static const _illustrations = {
    'mascot': mascot,
    'castle': 'assets/images/universe_castle.webp',
    'dragon': 'assets/images/universe_dragon.webp',
    'forest': 'assets/images/universe_forest.webp',
    'christmas': 'assets/images/universe_christmas.webp',
  };

  /// Illustration d'un thème ; château provisoire tant que l'illustration manque (charte §8).
  static String illustration(String key) => _illustrations[key] ?? _illustrations['castle']!;
}

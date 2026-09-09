/// Modèle de donnée d'un événement.
///
/// Ce TP porte sur la navigation, pas sur la modélisation : le modèle est
/// volontairement minimal, mais porte un [id] stable car la Partie C exige
/// de pouvoir désigner un événement par identifiant plutôt que par objet.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.city,
    required this.venue,
    required this.date,
    required this.category,
    required this.capaciteTotale,
    required this.placesPrises,
  });

  final String id;
  final String title;
  final String city;
  final String venue;
  final DateTime date;
  final String category;
  final int capaciteTotale;
  final int placesPrises;

  /// Taux de remplissage entre 0.0 et 1.0, utilisé par la jauge de places.
  double get tauxRemplissage =>
      capaciteTotale == 0 ? 0 : placesPrises / capaciteTotale;

  /// Date formatée manuellement : aucune dépendance externe (`intl`) n'est
  /// nécessaire pour un TP centré sur la navigation.
  String get dateFormatee {
    const List<String> mois = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

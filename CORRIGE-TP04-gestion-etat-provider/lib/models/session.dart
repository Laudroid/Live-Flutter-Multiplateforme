/// Une session appartenant à un événement (par exemple un atelier ou une
/// conférence dans une journée). Purement Dart, aucune dépendance Flutter :
/// ce modèle est un simple porteur de données.
class Session {
  const Session({
    required this.id,
    required this.libelle,
    required this.horaire,
  });

  final String id;
  final String libelle;

  /// Horaire sous forme de chaîne libre (ex. "09h00 - 10h30"), conformément
  /// à l'énoncé qui ne demande pas de type `DateTime` en Partie B.
  final String horaire;
}

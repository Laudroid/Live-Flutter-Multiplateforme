/// Modèle de données immuable représentant un événement du cycle de
/// conférences. Reproduit exactement la signature imposée par l'énoncé du
/// TP 2 : aucun champ ajouté, aucune méthode métier, uniquement des données.
class Event {
  const Event({
    required this.title,
    required this.city,
    required this.venue,
    required this.date,
    required this.category,
    required this.capacity,
    required this.registered,
    required this.imageUrl,
    this.isSoldOut = false,
    this.isOnline = false,
  });

  final String title; // peut être long, voir sample_events.dart
  final String city;
  final String venue;
  final DateTime date;
  final String category; // « Conférence », « Atelier », « Meetup », « Table ronde »
  final int capacity;
  final int registered; // peut dépasser capacity : liste d'attente
  final String imageUrl;
  final bool isSoldOut;
  final bool isOnline;
}

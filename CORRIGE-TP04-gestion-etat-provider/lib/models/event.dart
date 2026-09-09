import 'session.dart';

/// Un événement du dépôt en dur. Toutes les instances de ce corrigé sont
/// construites `const` dans `EventRepository` : le dépôt lui-même n'est
/// jamais muté, seul le panier (état séparé) change au fil de l'usage.
class Event {
  const Event({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.capacite,
    required this.placesPrises,
    required this.sessions,
  });

  final String id;
  final String titre;
  final String categorie;
  final int capacite;

  /// Places déjà occupées avant toute action de l'utilisateur courant
  /// (autres participants). Ne varie jamais dans ce dépôt en mémoire.
  final int placesPrises;
  final List<Session> sessions;

  int get placesRestantesInitiales => capacite - placesPrises;
}

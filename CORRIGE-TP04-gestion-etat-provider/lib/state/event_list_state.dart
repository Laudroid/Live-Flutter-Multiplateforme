import '../models/event.dart';

/// Machine à états scellée pour le chargement de la liste d'événements
/// (Partie C.4). Une `sealed class` interdit par construction un état
/// incohérent tel que « en cours de chargement ET en erreur » : le
/// compilateur force un `switch` exhaustif sur les trois sous-types, alors
/// que deux booléens indépendants (`isLoading`, `hasError`) auraient permis
/// d'atteindre des combinaisons absurdes sans qu'aucune erreur de
/// compilation ne le signale.
sealed class EventListState {
  const EventListState();
}

class EventListLoading extends EventListState {
  const EventListLoading();
}

class EventListLoaded extends EventListState {
  const EventListLoaded(this.evenements);
  final List<Event> evenements;
}

class EventListError extends EventListState {
  const EventListError(this.message);
  final String message;
}

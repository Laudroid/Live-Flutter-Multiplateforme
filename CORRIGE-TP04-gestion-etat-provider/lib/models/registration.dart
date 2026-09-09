import 'event.dart';
import 'session.dart';

/// Une ligne du panier : un événement, la session choisie et la quantité de
/// places réservées par l'utilisateur courant pour cette inscription.
///
/// Immuable : toute modification de quantité passe par `copyWith`, appelé
/// uniquement depuis `RegistrationCart` (jamais depuis un widget).
class Registration {
  const Registration({
    required this.event,
    required this.session,
    required this.quantite,
  });

  final Event event;
  final Session session;
  final int quantite;

  Registration copyWith({int? quantite}) => Registration(
        event: event,
        session: session,
        quantite: quantite ?? this.quantite,
      );
}

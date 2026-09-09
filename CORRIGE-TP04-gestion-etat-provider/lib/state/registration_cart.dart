// Contrainte de découplage stricte de l'énoncé (B.2) : ce fichier n'importe
// AUCUN paquet de widgets Flutter. Seul `foundation.dart` est utilisé, pour
// `ChangeNotifier`. Le panier est un état pur, testable sans monter le
// moindre widget, et aucune ligne d'affichage ne peut s'y glisser par
// inadvertance.
import 'package:flutter/foundation.dart';

import '../data/event_repository.dart';
import '../models/event.dart';
import '../models/registration.dart';
import '../models/session.dart';

/// Résultat exploitable d'une tentative d'ajout au panier. L'énoncé (B.2)
/// exige que tout refus soit signalé par une valeur de retour, pas par un
/// simple `print` : un `enum` de résultat est plus explicite qu'un booléen
/// (l'appelant sait pourquoi l'opération a échoué et peut adapter le
/// message affiché).
enum ResultatAjout {
  succes,

  /// Choix documenté pour la contrainte « un même événement ne peut pas
  /// être ajouté deux fois » : une seconde tentative d'ajout sur un
  /// événement déjà présent est REFUSÉE (elle ne modifie pas la quantité
  /// existante). Pour changer la quantité d'une inscription déjà présente,
  /// l'appelant doit utiliser `modifierQuantite`. Ce choix évite qu'un
  /// double-tap accidentel sur « ajouter » ne change silencieusement une
  /// quantité que l'utilisateur avait déjà ajustée à la main.
  dejaDansLePanier,

  /// Places prises (dépôt) + places déjà réservées dans le panier pour cet
  /// événement + quantité demandée dépasseraient la capacité.
  evenementComplet,

  /// Le plafond de places par utilisateur, toutes inscriptions confondues,
  /// serait dépassé.
  plafondDepasse,
}

/// Résultat exploitable d'une modification de quantité sur une inscription
/// déjà présente dans le panier.
enum ResultatModification {
  succes,
  inscriptionInconnue,
  evenementComplet,
  plafondDepasse,
}

/// Notifier du panier d'inscriptions.
///
/// Le dépôt (`EventRepository`) est injecté par le constructeur (voir
/// `ChangeNotifierProxyProvider` dans `main.dart`, Partie C.3) : ce notifier
/// ne construit jamais son propre dépôt. `updateRepository` permet au
/// `ProxyProvider` de propager un dépôt éventuellement recréé sans perdre
/// l'état du panier déjà accumulé (le panier `previousCart` est conservé,
/// seule sa dépendance est rafraîchie).
class RegistrationCart extends ChangeNotifier {
  RegistrationCart({required EventRepository depot}) : _repository = depot;

  EventRepository _repository;

  /// Plafond de places par utilisateur, toutes inscriptions confondues.
  /// Valeur arbitraire mais documentée : au-delà de 8 places réservées
  /// simultanément, on considère qu'il s'agit d'une erreur de saisie ou
  /// d'un abus, et l'énoncé demande explicitement qu'une limite existe.
  static const int plafondPlaces = 8;

  final List<Registration> _inscriptions = [];

  /// Copie défensive : aucun widget ne doit pouvoir muter la liste interne
  /// en la castant depuis le getter.
  List<Registration> get inscriptions => List.unmodifiable(_inscriptions);

  int get totalPlacesReservees =>
      _inscriptions.fold(0, (somme, r) => somme + r.quantite);

  int get nombreEvenementsDistincts => _inscriptions.length;

  /// Utilisé par la démonstration Selector de la Partie C : cette lecture
  /// isolée d'un booléen par identifiant d'événement permet à une tuile de
  /// ne se recomposer que lorsque SON statut « dans le panier » change,
  /// plutôt qu'à chaque mutation du panier entier.
  bool estDansLePanier(String eventId) =>
      _inscriptions.any((r) => r.event.id == eventId);

  Registration? _trouverInscription(String eventId) {
    for (final r in _inscriptions) {
      if (r.event.id == eventId) return r;
    }
    return null;
  }

  /// Relit l'événement depuis le dépôt injecté plutôt que de faire
  /// confiance à l'objet `Event` transmis par l'appelant : c'est la raison
  /// concrète d'être de l'injection par `ChangeNotifierProxyProvider`
  /// (Partie C.3). Si le dépôt ne connaît plus cet événement (invalidé
  /// entre-temps), on retombe sur la valeur transmise plutôt que de
  /// planter.
  Event _capaciteAJour(Event event) => _repository.parId(event.id) ?? event;

  /// Met à jour le dépôt injecté. Appelé uniquement par le `update` du
  /// `ChangeNotifierProxyProvider` — jamais par un widget.
  void updateRepository(EventRepository repository) {
    _repository = repository;
  }

  ResultatAjout ajouter({
    required Event event,
    required Session session,
    required int quantite,
  }) {
    if (estDansLePanier(event.id)) {
      return ResultatAjout.dejaDansLePanier;
    }
    final referenceEvent = _capaciteAJour(event);
    final placesRestantes = referenceEvent.capacite - referenceEvent.placesPrises;
    if (quantite > placesRestantes) {
      return ResultatAjout.evenementComplet;
    }
    if (totalPlacesReservees + quantite > plafondPlaces) {
      return ResultatAjout.plafondDepasse;
    }
    _inscriptions.add(
      Registration(event: event, session: session, quantite: quantite),
    );
    notifyListeners();
    return ResultatAjout.succes;
  }

  bool retirer(String eventId) {
    final tailleAvant = _inscriptions.length;
    _inscriptions.removeWhere((r) => r.event.id == eventId);
    final aRetire = _inscriptions.length != tailleAvant;
    if (aRetire) notifyListeners();
    return aRetire;
  }

  ResultatModification modifierQuantite({
    required String eventId,
    required int nouvelleQuantite,
  }) {
    final inscription = _trouverInscription(eventId);
    if (inscription == null) return ResultatModification.inscriptionInconnue;

    final referenceEvent = _capaciteAJour(inscription.event);
    final placesRestantes = referenceEvent.capacite - referenceEvent.placesPrises;
    if (nouvelleQuantite > placesRestantes) {
      return ResultatModification.evenementComplet;
    }
    final totalSansCetteInscription =
        totalPlacesReservees - inscription.quantite;
    if (totalSansCetteInscription + nouvelleQuantite > plafondPlaces) {
      return ResultatModification.plafondDepasse;
    }

    final index = _inscriptions.indexOf(inscription);
    _inscriptions[index] = inscription.copyWith(quantite: nouvelleQuantite);
    notifyListeners();
    return ResultatModification.succes;
  }

  void vider() {
    if (_inscriptions.isEmpty) return;
    _inscriptions.clear();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../data/event_repository.dart';
import 'event_list_state.dart';

/// Notifier responsable du chargement de la liste d'événements, avec un
/// état représenté par la machine à états scellée `EventListState`
/// (Partie C.4).
///
/// Le dépôt est injecté par le constructeur (voir `ChangeNotifierProxyProvider`
/// dans `main.dart`) : ce notifier ne construit jamais son propre
/// `EventRepository`.
///
/// `Future.delayed` simule une latence d'accès au dépôt, uniquement pour
/// illustrer l'état de chargement (aucun appel réseau réel, conformément au
/// périmètre du TP). Le drapeau `_disposed` évite d'appeler
/// `notifyListeners()` après que le notifier a été détruit : un écran de
/// détail peut être fermé pendant que le `Future.delayed` est encore en
/// attente, et sans cette garde l'appel tardif à `notifyListeners()`
/// lèverait une exception sur un `ChangeNotifier` déjà disposé.
class EventListNotifier extends ChangeNotifier {
  EventListNotifier({required EventRepository depot}) : _repository = depot {
    // Le chargement initial est déclenché ici, mais l'unique
    // `notifyListeners()` qu'il produit n'a lieu qu'après le `await` du
    // `Future.delayed`, donc jamais de façon synchrone pendant la
    // construction de l'arbre de widgets qui consommera ce notifier.
    charger();
  }

  EventRepository _repository;
  EventListState _state = const EventListLoading();
  bool _disposed = false;

  EventListState get state => _state;

  void updateRepository(EventRepository repository) {
    _repository = repository;
  }

  /// Recharge la liste. `simulerEchec` permet de déclencher volontairement
  /// le cas d'erreur depuis un bouton de test, sans panne réseau réelle.
  Future<void> charger({bool simulerEchec = false}) async {
    _state = const EventListLoading();
    // Appelé depuis un bouton (nouvelle tentative) ou depuis le
    // constructeur avant tout listener : jamais pendant un `build`.
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    if (_disposed) return;

    _state = simulerEchec
        ? const EventListError(
            "Impossible de charger les événements (échec simulé).",
          )
        : EventListLoaded(_repository.tousLesEvenements());
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

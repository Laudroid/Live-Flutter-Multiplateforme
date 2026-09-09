import '../models/event.dart';
import '../models/session.dart';

/// Dépôt de données en mémoire, codé en dur, conformément au périmètre du
/// TP4 (pas d'appel réseau réel). Les listes exposées sont volontairement
/// immuables (`const`/`List.unmodifiable` implicite via `const`) : ce dépôt
/// ne mute jamais ses propres données, seules les inscriptions du panier
/// (état séparé, voir `RegistrationCart`) évoluent.
///
/// En Partie C, ce dépôt est injecté dans `RegistrationCart` et dans
/// `EventListNotifier` via `Provider`/`ChangeNotifierProxyProvider` plutôt
/// que construit à l'intérieur des notifiers : cela permettra, en séance 5,
/// de le remplacer par une implémentation qui interroge une vraie source de
/// données sans toucher au code des notifiers.
class EventRepository {
  const EventRepository();

  static const List<Event> _evenements = [
    Event(
      id: 'evt-1',
      titre: 'Conférence Flutter avancé',
      categorie: 'Conférence',
      capacite: 5,
      placesPrises: 4,
      sessions: [
        Session(id: 'evt-1-s1', libelle: 'Keynote ouverture', horaire: '09h00 - 10h00'),
        Session(id: 'evt-1-s2', libelle: 'Table ronde', horaire: '10h15 - 11h30'),
      ],
    ),
    Event(
      id: 'evt-2',
      titre: 'Atelier Provider en pratique',
      categorie: 'Atelier',
      capacite: 20,
      placesPrises: 6,
      sessions: [
        Session(id: 'evt-2-s1', libelle: 'Session matin', horaire: '09h00 - 12h00'),
        Session(id: 'evt-2-s2', libelle: 'Session après-midi', horaire: '14h00 - 17h00'),
      ],
    ),
    Event(
      id: 'evt-3',
      titre: 'Atelier architecture d\'état',
      categorie: 'Atelier',
      capacite: 15,
      placesPrises: 15,
      sessions: [
        Session(id: 'evt-3-s1', libelle: 'Session unique', horaire: '13h00 - 16h00'),
      ],
    ),
    Event(
      id: 'evt-4',
      titre: 'Networking développeurs mobiles',
      categorie: 'Networking',
      capacite: 50,
      placesPrises: 12,
      sessions: [
        Session(id: 'evt-4-s1', libelle: 'Cocktail', horaire: '18h00 - 20h00'),
      ],
    ),
    Event(
      id: 'evt-5',
      titre: 'Conférence Dart 3 et null-safety avancée',
      categorie: 'Conférence',
      capacite: 30,
      placesPrises: 3,
      sessions: [
        Session(id: 'evt-5-s1', libelle: 'Présentation', horaire: '11h00 - 12h00'),
      ],
    ),
  ];

  List<Event> tousLesEvenements() => _evenements;

  Event? parId(String id) {
    for (final evenement in _evenements) {
      if (evenement.id == id) return evenement;
    }
    return null;
  }

  List<String> toutesLesCategories() =>
      _evenements.map((e) => e.categorie).toSet().toList()..sort();
}

import '../models/event.dart';

/// Jeu de données codé en dur, réimplémenté pour ce corrigé autonome (le TP3
/// ne suppose aucun fichier venant d'un corrigé du TP2).
// `DateTime()` n'est pas un constructeur `const` : la liste ne peut donc pas
// être `const`, seulement `final`.
final List<Event> sampleEvents = <Event>[
  Event(
    id: 'evt-001',
    title: 'Salon du Numérique Responsable',
    city: 'Nantes',
    venue: 'Cité des Congrès',
    date: DateTime(2026, 10, 12),
    category: 'Conférence',
    capaciteTotale: 400,
    placesPrises: 372,
  ),
  Event(
    id: 'evt-002',
    title: 'Nuit du Court-Métrage',
    city: 'Lyon',
    venue: 'Institut Lumière',
    date: DateTime(2026, 9, 20),
    category: 'Projection',
    capaciteTotale: 180,
    placesPrises: 96,
  ),
  Event(
    id: 'evt-003',
    title: 'Atelier Cuisine Végétale',
    city: 'Bordeaux',
    venue: 'Halle Darwin',
    date: DateTime(2026, 9, 27),
    category: 'Atelier',
    capaciteTotale: 30,
    placesPrises: 30,
  ),
  Event(
    id: 'evt-004',
    title: 'Marathon des Vignobles',
    city: 'Colmar',
    venue: 'Place Rapp',
    date: DateTime(2026, 11, 8),
    category: 'Sport',
    capaciteTotale: 2000,
    placesPrises: 1450,
  ),
  Event(
    id: 'evt-005',
    title: 'Forum Emploi Tech',
    city: 'Toulouse',
    venue: 'Parc des Expositions',
    date: DateTime(2026, 10, 3),
    category: 'Recrutement',
    capaciteTotale: 600,
    placesPrises: 210,
  ),
];

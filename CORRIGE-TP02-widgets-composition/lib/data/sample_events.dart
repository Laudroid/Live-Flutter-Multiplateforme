import '../models/event.dart';

/// Jeu de données codé en dur, conformément au périmètre du TP (aucun appel
/// réseau, aucune source distante pour les données elles-mêmes — seules les
/// vignettes sont chargées via `Image.network`, à titre d'illustration).
///
/// Les images utilisent le service picsum.photos avec une graine (`seed`)
/// fixe : l'URL est stable et reproductible, ce qui est essentiel pour un
/// corrigé destiné à être rejoué. `EventCard` prévoit un `errorBuilder` pour
/// que l'absence de réseau (cas de ce conteneur de production) ne casse pas
/// la mise en page.
///
/// Cas limites imposés par l'énoncé, présents dans cette liste :
/// - un titre de plus de 70 caractères (index 0) ;
/// - un événement complet, `isSoldOut: true` (index 1) ;
/// - un événement en ligne sans ville utile (index 2) ;
/// - un événement en sur-réservation, `registered > capacity` (index 3) ;
/// - un nom de lieu très long (index 4).
final List<Event> sampleEvents = [
  Event(
    title:
        'Conférence annuelle sur l\'ingénierie des systèmes distribués et la résilience logicielle',
    city: 'Lyon',
    venue: 'Centre des congrès',
    date: DateTime(2026, 9, 5, 9, 0),
    category: 'Conférence',
    capacity: 300,
    registered: 180,
    imageUrl: 'https://picsum.photos/seed/event-distribues/400/400',
  ),
  Event(
    title: 'Atelier Flutter avancé',
    city: 'Nantes',
    venue: 'Le Hangar',
    date: DateTime(2026, 9, 10, 9, 30),
    category: 'Atelier',
    capacity: 40,
    registered: 40,
    imageUrl: 'https://picsum.photos/seed/event-flutter/400/400',
    isSoldOut: true,
  ),
  Event(
    title: 'Meetup en ligne : observabilité et traces distribuées',
    city: '',
    venue: 'Diffusion en direct',
    date: DateTime(2026, 9, 15, 18, 0),
    category: 'Meetup',
    capacity: 500,
    registered: 210,
    imageUrl: 'https://picsum.photos/seed/event-online/400/400',
    isOnline: true,
  ),
  Event(
    title: 'Table ronde : éthique et intelligence artificielle',
    city: 'Paris',
    venue: 'Maison de la Recherche',
    date: DateTime(2026, 9, 20, 19, 0),
    category: 'Table ronde',
    capacity: 80,
    registered: 97,
    imageUrl: 'https://picsum.photos/seed/event-ethique/400/400',
  ),
  Event(
    title: 'Meetup mobile Kotlin & Flutter',
    city: 'Toulouse',
    venue:
        'Espace de coworking La Cordée — bâtiment B, troisième étage, salle Ariane',
    date: DateTime(2026, 9, 22, 18, 30),
    category: 'Meetup',
    capacity: 60,
    registered: 25,
    imageUrl: 'https://picsum.photos/seed/event-mobile/400/400',
  ),
  Event(
    title: 'Atelier découverte du Dart',
    city: 'Bordeaux',
    venue: 'Campus numérique',
    date: DateTime(2026, 9, 25, 14, 0),
    category: 'Atelier',
    capacity: 30,
    registered: 12,
    imageUrl: 'https://picsum.photos/seed/event-dart/400/400',
  ),
  Event(
    title: 'Conférence : architectures hexagonales en pratique',
    city: 'Lille',
    venue: 'Auditorium Euratechnologies',
    date: DateTime(2026, 10, 1, 9, 0),
    category: 'Conférence',
    capacity: 250,
    registered: 140,
    imageUrl: 'https://picsum.photos/seed/event-hexagonale/400/400',
  ),
  Event(
    title: 'Table ronde : carrières dans la tech',
    city: 'Marseille',
    venue: 'La Coque',
    date: DateTime(2026, 10, 4, 17, 30),
    category: 'Table ronde',
    capacity: 120,
    registered: 45,
    imageUrl: 'https://picsum.photos/seed/event-carrieres/400/400',
  ),
];

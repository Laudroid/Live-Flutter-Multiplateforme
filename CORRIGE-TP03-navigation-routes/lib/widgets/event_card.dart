import 'package:flutter/material.dart';

import '../models/event.dart';
import 'jauge_places.dart';

/// Carte d'un événement sur le mur d'accueil.
///
/// [onTap] déclenche le parcours de navigation « officiel » (Partie C, route
/// nommée validée par identifiant). [onLongPress] est optionnel et sert
/// uniquement à exposer, en appui long, les deux démonstrations historiques
/// de la Partie A (push direct, puis route nommée avec objet) — voir
/// `EventWallScreen`.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onLongPress,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(label: Text(event.category)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${event.venue} — ${event.city}'),
              Text(event.dateFormatee),
              const SizedBox(height: 8),
              JaugePlaces(
                taux: event.tauxRemplissage,
                libelle:
                    '${event.placesPrises} / ${event.capaciteTotale} places prises',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

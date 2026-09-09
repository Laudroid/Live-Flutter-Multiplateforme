import 'package:flutter/material.dart';

import '../models/event.dart';

/// Ce fichier conserve, à des fins pédagogiques, les deux étapes
/// intermédiaires demandées par la Partie A avant leur remplacement par la
/// version finale à identifiant validé de la Partie C
/// (`event_detail_screen.dart`).
///
/// Accès dans l'application : appui long sur une carte du mur d'événements
/// (voir `EventWallScreen._ouvrirMenuDemo`).

/// PARTIE A.1 — navigation impérative directe.
///
/// `Navigator.push` construit un `MaterialPageRoute` sans nom, et l'objet
/// `Event` complet est fourni directement au constructeur du widget. C'est
/// la forme la plus simple, mais elle interdit toute route nommée
/// (`pushNamed`) et toute résolution centralisée des arguments : c'est
/// justement ce que la suite du TP corrige.
class EventDetailPushDemoScreen extends StatelessWidget {
  const EventDetailPushDemoScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: _CorpsDemo(
        event: event,
        bandeau:
            'Démo Partie A.1 — Navigator.push(MaterialPageRoute) avec '
            'objet Event passé au constructeur.',
      ),
    );
  }
}

/// PARTIE A.2 — migration vers une route nommée statique.
///
/// Cette route est déclarée dans la table `routes:` du `MaterialApp`
/// (`AppRoutes.eventDetailNamedArgsDemo`), pas via `onGenerateRoute` : une
/// entrée de `routes:` reçoit un simple `WidgetBuilder(BuildContext)`, sans
/// accès direct aux arguments. L'objet `Event` transite malgré tout via
/// `Navigator.pushNamed(..., arguments: event)` et doit être relu à
/// l'intérieur du widget avec `ModalRoute.of(context)!.settings.arguments`,
/// castés explicitement — exactement la méthode décrite par l'énoncé A.2.4.
class EventDetailNamedArgsDemoScreen extends StatelessWidget {
  const EventDetailNamedArgsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Event event =
        ModalRoute.of(context)!.settings.arguments as Event;
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: _CorpsDemo(
        event: event,
        bandeau:
            'Démo Partie A.2 — pushNamed + objet Event lu via '
            'ModalRoute.of(context)!.settings.arguments.',
      ),
    );
  }
}

class _CorpsDemo extends StatelessWidget {
  const _CorpsDemo({required this.event, required this.bandeau});

  final Event event;
  final String bandeau;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(bandeau),
        ),
        const SizedBox(height: 16),
        Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${event.venue}, ${event.city}'),
        Text(event.dateFormatee),
        const SizedBox(height: 8),
        Chip(label: Text(event.category)),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../models/event.dart';
import '../routes/app_routes.dart';
import '../widgets/event_card.dart';
import 'legacy_navigation_demo_screens.dart';

/// Mur d'événements — écran d'accueil, point d'entrée et point de retour
/// final de tout le parcours de navigation.
class EventWallScreen extends StatelessWidget {
  const EventWallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Planner — mur des événements')),
      body: ListView.builder(
        itemCount: sampleEvents.length,
        itemBuilder: (BuildContext context, int index) {
          final Event event = sampleEvents[index];
          return EventCard(
            event: event,
            onTap: () => _ouvrirDetail(context, event),
            onLongPress: () => _ouvrirMenuDemo(context, event),
          );
        },
      ),
    );
  }

  /// Parcours de production (Partie C) : route nommée par identifiant,
  /// validée et résolue par `RouteGenerator`. Seule cette forme apparaît
  /// dans le parcours normal de l'application.
  void _ouvrirDetail(BuildContext context, Event event) {
    Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: event.id);
  }

  /// Menu de démonstration (appui long) : donne accès aux deux techniques
  /// historiques de la Partie A, conservées pour comparaison pédagogique.
  Future<void> _ouvrirMenuDemo(BuildContext context, Event event) async {
    final String? choix = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Démonstrations de la Partie A'),
              ),
              ListTile(
                leading: const Icon(Icons.call_made),
                title: const Text('A.1 — Navigator.push (objet direct)'),
                onTap: () => Navigator.pop(context, 'a1'),
              ),
              ListTile(
                leading: const Icon(Icons.route),
                title: const Text(
                  'A.2 — pushNamed (objet via RouteSettings)',
                ),
                onTap: () => Navigator.pop(context, 'a2'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || choix == null) {
      return;
    }

    if (choix == 'a1') {
      // PARTIE A.1 — navigation impérative directe : Navigator.push avec un
      // MaterialPageRoute construit inline, objet Event complet passé au
      // constructeur du widget de destination.
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EventDetailPushDemoScreen(event: event),
        ),
      );
    } else {
      // PARTIE A.2 — route nommée statique (table `routes:` du
      // MaterialApp) ; l'objet Event voyage via RouteSettings.arguments.
      Navigator.pushNamed(
        context,
        AppRoutes.eventDetailNamedArgsDemo,
        arguments: event,
      );
    }
  }
}

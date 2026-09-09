import 'package:flutter/material.dart';

import '../widgets/demo_avant/cart_badge_callback.dart';
import '../widgets/demo_avant/compteurs_demo.dart';
import '../widgets/demo_avant/event_section_callback.dart';

/// Partie A.1 — démonstration « AVANT » : un compteur d'inscriptions géré
/// par `setState` au niveau 1 (`_EventListScreenCallbacksState`), remonté
/// par callbacks à travers trois niveaux de widgets
/// (`EventListScreenCallbacks` -> `EventSectionCallback` ->
/// `EventTileCallback`) et transmis séparément à `CartBadgeCallback`.
///
/// Ce widget est un `StatefulWidget` : c'est le point de départ imposé par
/// l'énoncé (A.1.2), avant toute notion de `ChangeNotifier`.
class EventListScreenCallbacks extends StatefulWidget {
  const EventListScreenCallbacks({super.key});

  @override
  State<EventListScreenCallbacks> createState() =>
      _EventListScreenCallbacksState();
}

class _EventListScreenCallbacksState extends State<EventListScreenCallbacks> {
  int _registrationCount = 0;

  void _increment() {
    setState(() {
      _registrationCount++;
    });
  }

  @override
  void initState() {
    super.initState();
    CompteursDemoAvant.remettreAZero();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démo AVANT — callbacks (setState)'),
        actions: [
          CartBadgeCallback(registrationCount: _registrationCount),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const _NoteDemo(
            texte:
                'Comparez ce nombre de reconstructions à l\'écran « APRÈS » : '
                'appuyez cinq fois sur « Inscrire (+1) » et relisez les '
                'compteurs "build #" affichés sur chaque widget.',
          ),
          const SizedBox(height: 8),
          EventSectionCallback(
            registrationCount: _registrationCount,
            onIncrement: _increment,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _EcranFacticeCallback(
                  compteurAuMomentDuPush: _registrationCount,
                ),
              ),
            ),
            child: const Text(
              'Naviguer vers un écran factice puis revenir (test A.1.5)',
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteDemo extends StatelessWidget {
  const _NoteDemo({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.amber.withValues(alpha: 0.2),
      child: Text(texte, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Écran factice utilisé pour le test de survie à la navigation (A.1.5).
/// Il reçoit le compteur en PARAMÈTRE, comme une simple donnée figée au
/// moment du `push` : il ne peut pas refléter une évolution ultérieure du
/// compteur pendant qu'il est affiché, contrairement à l'équivalent
/// `ChangeNotifier` de la Partie A.3 (`_EcranFacticeApres`), qui lit l'état
/// en direct sans qu'on le lui ait transmis.
class _EcranFacticeCallback extends StatelessWidget {
  const _EcranFacticeCallback({required this.compteurAuMomentDuPush});

  final int compteurAuMomentDuPush;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Écran factice (callbacks)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valeur reçue au moment du push : $compteurAuMomentDuPush\n\n'
                'Cet écran ne peut PAS afficher une valeur à jour si le '
                'compteur change ailleurs pendant qu\'il est affiché : il '
                'n\'a reçu qu\'un instantané, pas un accès à l\'état.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour (Navigator.pop)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

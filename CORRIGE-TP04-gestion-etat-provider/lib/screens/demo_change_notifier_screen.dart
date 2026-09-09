import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/demo_counter.dart';
import '../widgets/demo_apres/cart_badge_after.dart';
import '../widgets/demo_apres/compteurs_demo_apres.dart';
import '../widgets/demo_apres/event_section_after.dart';

/// Partie A.3 — démonstration « APRÈS » : le même scénario que
/// `EventListScreenCallbacks`, mais le compteur vit dans `DemoCounterNotifier`,
/// fourni par un `ChangeNotifierProvider` placé au-dessus de `MaterialApp`
/// (voir `main.dart`). Aucun widget de cet écran ne reçoit le compteur ou
/// le callback d'incrémentation en paramètre : `EventTileAfter` et
/// `CartBadgeAfter` le lisent chacun indépendamment via `context.watch`.
///
/// Ce widget est un `StatelessWidget` : il n'a plus besoin d'être un
/// `StatefulWidget` puisqu'il ne détient plus lui-même aucun état mutable.
class EventListScreenAfter extends StatelessWidget {
  const EventListScreenAfter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démo APRÈS — ChangeNotifier'),
        actions: const [CartBadgeAfter()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green.withValues(alpha: 0.15),
            child: Text(
              'EventSectionAfter ne reçoit plus rien en paramètre : son '
              'compteur "build #" doit rester à 1 après plusieurs '
              'incréments, contrairement à EventSectionCallback.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          const EventSectionAfter(),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                CompteursDemoApres.remettreAZero();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _EcranFacticeApres()),
                );
              },
              child: const Text(
                'Naviguer vers un écran factice puis revenir (test A.3.6)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran factice équivalent de `_EcranFacticeCallback`, mais qui affiche le
/// badge LIVE sans avoir reçu la moindre donnée en paramètre : le compteur
/// vit au-dessus de `MaterialApp`, donc au-dessus du `Navigator` lui-même,
/// et survit par construction à n'importe quel `push`/`pop`.
class _EcranFacticeApres extends StatelessWidget {
  const _EcranFacticeApres();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Écran factice (ChangeNotifier)'),
        actions: const [CartBadgeAfter()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ce badge n\'a reçu AUCUN paramètre : il lit '
                'DemoCounterNotifier directement, comme sur l\'écran '
                'précédent. Incrémentez depuis l\'écran précédent après '
                'être revenu en arrière pour constater la mise à jour '
                'instantanée.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<DemoCounterNotifier>().increment();
                },
                child: const Text('Inscrire (+1) depuis cet écran aussi'),
              ),
              const SizedBox(height: 12),
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

import 'package:flutter/material.dart';

import 'compteurs_demo_apres.dart';
import 'event_tile_after.dart';

/// Équivalent de `EventSectionCallback` après migration. Ne reçoit plus
/// AUCUN paramètre lié au compteur : il n'a donc plus aucune raison de se
/// reconstruire lors d'un incrément. C'est la preuve chiffrée demandée en
/// A.3 (« le tableau de recompositions avant/après montre que
/// `EventSection` n'est plus reconstruit du tout »).
class EventSectionAfter extends StatelessWidget {
  const EventSectionAfter({super.key});

  @override
  Widget build(BuildContext context) {
    CompteursDemoApres.eventSection++;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Section « Ateliers » (build #${CompteursDemoApres.eventSection})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const EventTileAfter(),
      ],
    );
  }
}

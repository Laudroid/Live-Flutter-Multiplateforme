import 'package:flutter/material.dart';

import 'compteurs_demo.dart';
import 'event_tile_callback.dart';

/// Niveau 2 de la chaîne de callbacks (Partie A.1) : ne consulte ni
/// n'affiche jamais `registrationCount` lui-même, il se contente de le
/// retransmettre à `EventTileCallback`. Il se reconstruit pourtant à
/// chaque incrément puisqu'il reçoit une nouvelle valeur en paramètre à
/// chaque appel de `setState` du parent — c'est ce que la migration vers
/// `ChangeNotifier` (A.3) élimine : `EventSectionAfter` ne recevra plus
/// rien du tout par paramètre et ne se reconstruira plus jamais pour cette
/// raison.
class EventSectionCallback extends StatelessWidget {
  const EventSectionCallback({
    super.key,
    required this.registrationCount,
    required this.onIncrement,
  });

  final int registrationCount;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    CompteursDemoAvant.eventSection++;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Section « Ateliers » (build #${CompteursDemoAvant.eventSection})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        EventTileCallback(
          registrationCount: registrationCount,
          onIncrement: onIncrement,
        ),
      ],
    );
  }
}

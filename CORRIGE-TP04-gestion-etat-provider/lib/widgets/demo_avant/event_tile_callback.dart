import 'package:flutter/material.dart';

import 'compteurs_demo.dart';

/// Niveau 3 de la chaîne de callbacks (Partie A.1) : reçoit le compteur ET
/// le callback d'incrémentation par paramètre, alors que lui seul les
/// utilise réellement. `EventSectionCallback`, au niveau au-dessus, ne fait
/// que les retransmettre sans s'en servir : c'est la « plomberie de
/// callbacks à travers des widgets qui n'utilisent pas eux-mêmes la
/// donnée » décrite en A.2.
class EventTileCallback extends StatelessWidget {
  const EventTileCallback({
    super.key,
    required this.registrationCount,
    required this.onIncrement,
  });

  final int registrationCount;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    CompteursDemoAvant.eventTile++;
    return Card(
      child: ListTile(
        title: const Text('Atelier Provider en pratique'),
        subtitle: Text(
          'Inscriptions locales : $registrationCount (build #${CompteursDemoAvant.eventTile})',
        ),
        trailing: ElevatedButton(
          onPressed: onIncrement,
          child: const Text('Inscrire (+1)'),
        ),
      ),
    );
  }
}

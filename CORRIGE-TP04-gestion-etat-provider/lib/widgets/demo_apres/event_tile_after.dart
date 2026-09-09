import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/demo_counter.dart';
import 'compteurs_demo_apres.dart';

/// Équivalent de `EventTileCallback` après migration : la valeur est lue
/// au plus près de l'affichage via `context.watch` (choix délibéré ici :
/// ce widget affiche l'entier lui-même, un `Selector` n'apporterait rien
/// puisqu'il n'y a qu'une seule donnée dans ce notifier de démonstration).
/// L'incrémentation passe par `context.read` dans le gestionnaire du
/// bouton, jamais dans `build` : lire avec `watch` et écrire avec `watch`
/// au même endroit provoquerait une reconstruction en boucle inutile et,
/// plus grave, un appel à une méthode de mutation pendant la phase de
/// construction si l'on tentait d'appeler `increment()` directement dans
/// `build`.
class EventTileAfter extends StatelessWidget {
  const EventTileAfter({super.key});

  @override
  Widget build(BuildContext context) {
    CompteursDemoApres.eventTile++;
    final count = context.watch<DemoCounterNotifier>().count;
    return Card(
      child: ListTile(
        title: const Text('Atelier Provider en pratique'),
        subtitle: Text(
          'Inscriptions locales : $count (build #${CompteursDemoApres.eventTile})',
        ),
        trailing: ElevatedButton(
          onPressed: () => context.read<DemoCounterNotifier>().increment(),
          child: const Text('Inscrire (+1)'),
        ),
      ),
    );
  }
}

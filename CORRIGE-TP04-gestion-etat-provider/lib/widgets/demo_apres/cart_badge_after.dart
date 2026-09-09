import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/demo_counter.dart';
import 'compteurs_demo_apres.dart';

/// Équivalent de `CartBadgeCallback` après migration : lit `DemoCounterNotifier`
/// directement, sans qu'aucun ancêtre n'ait à le lui transmettre. Point
/// clé de la démonstration : ce widget est aussi monté sur l'écran factice
/// poussé par la navigation (`DemoSecondScreenAfter`), qui ne reçoit lui-même
/// aucun paramètre lié au panier — la version callback ne peut pas offrir
/// cela sans replumber un paramètre supplémentaire à travers chaque route.
class CartBadgeAfter extends StatelessWidget {
  const CartBadgeAfter({super.key});

  @override
  Widget build(BuildContext context) {
    CompteursDemoApres.cartBadge++;
    final count = context.watch<DemoCounterNotifier>().count;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Text(
          'Panier : $count (build #${CompteursDemoApres.cartBadge})',
        ),
      ),
    );
  }
}

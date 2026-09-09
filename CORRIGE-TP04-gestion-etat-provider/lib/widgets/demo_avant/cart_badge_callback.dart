import 'package:flutter/material.dart';

import 'compteurs_demo.dart';

/// Niveau « AppBar » de la démonstration A.1 : reçoit le compteur en
/// paramètre, comme `EventSectionCallback` et `EventTileCallback`. Il ne
/// dépend d'aucun état global : c'est exactement le problème que la Partie
/// A.3 corrige (voir `CartBadgeAfter`, qui lit l'état directement).
class CartBadgeCallback extends StatelessWidget {
  const CartBadgeCallback({super.key, required this.registrationCount});

  final int registrationCount;

  @override
  Widget build(BuildContext context) {
    CompteursDemoAvant.cartBadge++;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Text(
          'Panier : $registrationCount (build #${CompteursDemoAvant.cartBadge})',
        ),
      ),
    );
  }
}

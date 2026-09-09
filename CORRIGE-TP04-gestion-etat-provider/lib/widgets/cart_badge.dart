import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/cart_summary_screen.dart';
import '../state/registration_cart.dart';

/// Badge de panier affiché dans l'`AppBar` de tous les écrans de
/// navigation (B.5). Aucun paramètre n'est reçu depuis l'écran parent :
/// ce widget lit `RegistrationCart` directement, où qu'il soit monté.
///
/// Choix `context.select` plutôt que `context.watch` : ce badge n'a besoin
/// que d'un entier (le total de places réservées), pas de l'objet
/// `RegistrationCart` entier. Avec `select`, ce widget ne se reconstruit
/// que lorsque cet entier change réellement — un ajout qui, par exemple,
/// ferait varier `nombreEvenementsDistincts` mais pas le total de places
/// (cas hypothétique) ne provoquerait aucune reconstruction ici.
class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context.select<RegistrationCart, int>(
      (cart) => cart.totalPlacesReservees,
    );

    return IconButton(
      tooltip: 'Voir le panier ($total place(s))',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartSummaryScreen()),
        );
      },
      icon: Badge(
        label: Text('$total'),
        isLabelVisible: total > 0,
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

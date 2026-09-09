import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/registration_cart.dart';

/// Écran de synthèse du panier, accessible depuis n'importe quel écran via
/// `CartBadge`. Démontre le scénario exigé en B.5 : un ajout effectué
/// depuis `EventDetailScreen`, une fois qu'on revient ici, apparaît sans
/// action supplémentaire puisque cet écran lit le même `RegistrationCart`
/// ambiant.
class CartSummaryScreen extends StatelessWidget {
  const CartSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch : cet écran EST la vue du panier, il doit se
    // reconstruire entièrement à chaque mutation. Pas de sous-partie à
    // isoler ici, contrairement à `EventTileSelectorCible`.
    final cart = context.watch<RegistrationCart>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: cart.inscriptions.isEmpty
          ? const Center(child: Text('Panier vide.'))
          : ListView(
              children: [
                for (final inscription in cart.inscriptions)
                  ListTile(
                    title: Text(inscription.event.titre),
                    subtitle: Text(
                      '${inscription.session.libelle} · '
                      '${inscription.quantite} place(s)',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: inscription.quantite > 1
                              ? () => _modifierQuantite(
                                    context,
                                    inscription.event.id,
                                    inscription.quantite - 1,
                                  )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _modifierQuantite(
                            context,
                            inscription.event.id,
                            inscription.quantite + 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => context
                              .read<RegistrationCart>()
                              .retirer(inscription.event.id),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Total : ${cart.totalPlacesReservees} place(s) sur '
                    '${cart.nombreEvenementsDistincts} événement(s) '
                    '(plafond : ${RegistrationCart.plafondPlaces})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
    );
  }

  void _modifierQuantite(BuildContext context, String eventId, int quantite) {
    final resultat = context.read<RegistrationCart>().modifierQuantite(
          eventId: eventId,
          nouvelleQuantite: quantite,
        );
    if (resultat != ResultatModification.succes) {
      final message = switch (resultat) {
        ResultatModification.succes => '',
        ResultatModification.inscriptionInconnue => 'Inscription introuvable.',
        ResultatModification.evenementComplet =>
          'Refusé : plus assez de places disponibles sur cet événement.',
        ResultatModification.plafondDepasse =>
          'Refusé : le plafond de ${RegistrationCart.plafondPlaces} places '
              'serait dépassé.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

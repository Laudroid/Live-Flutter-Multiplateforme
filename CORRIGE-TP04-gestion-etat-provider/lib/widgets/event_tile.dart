import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../state/registration_cart.dart';

/// Compteurs de reconstruction visibles à l'écran (Partie C.1).
class CompteursReconstruction {
  static int tuileConsumerLarge = 0;
  static int tuileSelectorCible = 0;

  static void remettreAZero() {
    tuileConsumerLarge = 0;
    tuileSelectorCible = 0;
  }
}

/// Configuration « large » de la Partie C.1 : la tuile observe l'état
/// ENTIER du panier via `context.watch<RegistrationCart>()`. N'importe
/// quelle mutation du panier (ajout sur un autre événement, changement de
/// quantité ailleurs, retrait d'une inscription qui ne concerne pas cette
/// tuile) provoque la reconstruction de CETTE tuile, alors que rien de ce
/// qu'elle affiche n'a changé. C'est le comportement à mesurer et à
/// comparer à la version ciblée ci-dessous.
class EventTileConsumerLarge extends StatelessWidget {
  const EventTileConsumerLarge({super.key, required this.event, required this.onAjouterRapide});

  final Event event;
  final VoidCallback onAjouterRapide;

  @override
  Widget build(BuildContext context) {
    CompteursReconstruction.tuileConsumerLarge++;
    // watch : ce widget veut être reconstruit à CHAQUE notification du
    // panier, quelle que soit la donnée qui a changé — c'est précisément
    // le défaut que la configuration ciblée corrige.
    final cart = context.watch<RegistrationCart>();
    final dansLePanier = cart.estDansLePanier(event.id);
    return _ContenuTuile(
      event: event,
      dansLePanier: dansLePanier,
      onAjouterRapide: onAjouterRapide,
      compteur: CompteursReconstruction.tuileConsumerLarge,
    );
  }
}

/// Configuration « ciblée » de la Partie C.1 : la tuile ne lit qu'un
/// booléen dérivé (« cet événement précis est-il dans le panier ? ») via
/// `context.select`. Provider compare la valeur du sélecteur avant/après
/// notification et ne reconstruit ce widget que si CETTE valeur a changé.
/// Une mutation du panier qui ne concerne pas cet événement ne provoque
/// donc aucune reconstruction ici.
class EventTileSelectorCible extends StatelessWidget {
  const EventTileSelectorCible({super.key, required this.event, required this.onAjouterRapide});

  final Event event;
  final VoidCallback onAjouterRapide;

  @override
  Widget build(BuildContext context) {
    CompteursReconstruction.tuileSelectorCible++;
    final dansLePanier = context.select<RegistrationCart, bool>(
      (cart) => cart.estDansLePanier(event.id),
    );
    return _ContenuTuile(
      event: event,
      dansLePanier: dansLePanier,
      onAjouterRapide: onAjouterRapide,
      compteur: CompteursReconstruction.tuileSelectorCible,
    );
  }
}

class _ContenuTuile extends StatelessWidget {
  const _ContenuTuile({
    required this.event,
    required this.dansLePanier,
    required this.onAjouterRapide,
    required this.compteur,
  });

  final Event event;
  final bool dansLePanier;
  final VoidCallback onAjouterRapide;
  final int compteur;

  @override
  Widget build(BuildContext context) {
    final placesRestantes = event.capacite - event.placesPrises;
    return Card(
      child: ListTile(
        title: Text(event.titre),
        subtitle: Text(
          '${event.categorie} · $placesRestantes place(s) restante(s) · reconstructions : $compteur',
        ),
        trailing: dansLePanier
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                tooltip: 'Ajouter une place',
                onPressed: onAjouterRapide,
              ),
      ),
    );
  }
}

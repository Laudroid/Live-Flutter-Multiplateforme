import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../state/display_preferences.dart';
import '../state/event_list_notifier.dart';
import '../state/event_list_state.dart';
import '../state/registration_cart.dart';
import '../widgets/cart_badge.dart';
import '../widgets/event_tile.dart';
import 'event_detail_screen.dart';

/// Écran réel de liste d'événements (Parties B et C). Contrairement aux
/// écrans de démonstration de la Partie A, celui-ci consomme
/// `RegistrationCart`, `DisplayPreferences` et `EventListNotifier`
/// exclusivement via les mécanismes de `provider` : aucun paramètre lié à
/// l'état global ne transite par le constructeur de ce widget.
class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  /// État strictement local à cet écran (bascule d'affichage pour la
  /// démonstration C.1) : il ne concerne que la façon dont CET écran
  /// affiche ses tuiles, aucun autre écran n'en a besoin. `setState`
  /// reste donc parfaitement approprié ici, conformément à ce que
  /// l'énoncé autorise pour de l'état « strictement local » après la
  /// Partie A.
  bool _configurationCiblee = true;

  @override
  Widget build(BuildContext context) {
    // context.watch ici est un choix délibéré : cet écran doit se
    // reconstruire entièrement dès que le statut de chargement change
    // (Loading -> Loaded -> Error), il n'y a pas de sous-partie à isoler.
    final etat = context.watch<EventListNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements (Partie B/C — Provider)'),
        actions: [
          PopupMenuButton<TriEvenements>(
            tooltip: 'Trier',
            icon: const Icon(Icons.sort),
            // context.read : on ne fait qu'écrire (changer le tri), cette
            // AppBar n'a pas besoin de se reconstruire quand le tri change.
            onSelected: (tri) =>
                context.read<DisplayPreferences>().changerTri(tri),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: TriEvenements.parTitre,
                child: Text('Trier par titre'),
              ),
              PopupMenuItem(
                value: TriEvenements.parPlacesRestantes,
                child: Text('Trier par places restantes'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Basculer densité',
            icon: const Icon(Icons.density_medium),
            onPressed: () {
              final prefs = context.read<DisplayPreferences>();
              final nouvelle = prefs.densite == DensiteAffichage.confortable
                  ? DensiteAffichage.compacte
                  : DensiteAffichage.confortable;
              prefs.changerDensite(nouvelle);
            },
          ),
          IconButton(
            tooltip: 'Simuler un échec de chargement (test C.4)',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () =>
                context.read<EventListNotifier>().charger(simulerEchec: true),
          ),
          const CartBadge(),
        ],
      ),
      body: switch (etat) {
        EventListLoading() => const Center(child: CircularProgressIndicator()),
        EventListError(:final message) => _VueErreur(message: message),
        EventListLoaded(:final evenements) => _VueListe(
            evenements: evenements,
            configurationCiblee: _configurationCiblee,
            onBasculerConfiguration: (valeur) {
              CompteursReconstruction.remettreAZero();
              setState(() => _configurationCiblee = valeur);
            },
          ),
      },
    );
  }
}

class _VueErreur extends StatelessWidget {
  const _VueErreur({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              // context.read : action ponctuelle, pas de lecture continue.
              onPressed: () => context.read<EventListNotifier>().charger(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VueListe extends StatelessWidget {
  const _VueListe({
    required this.evenements,
    required this.configurationCiblee,
    required this.onBasculerConfiguration,
  });

  final List<Event> evenements;
  final bool configurationCiblee;
  final ValueChanged<bool> onBasculerConfiguration;

  List<Event> _trierEtFiltrer(BuildContext context, List<Event> source) {
    // context.watch : la liste affichée doit se reconstruire dès que le
    // tri ou le filtre change ; c'est la donnée principale de cet écran,
    // un `select` n'apporterait rien puisque tri ET filtre sont tous deux
    // utilisés ici.
    final prefs = context.watch<DisplayPreferences>();
    var liste = source.where((e) {
      return prefs.categorieFiltre == null ||
          e.categorie == prefs.categorieFiltre;
    }).toList();
    liste.sort((a, b) => switch (prefs.tri) {
          TriEvenements.parTitre => a.titre.compareTo(b.titre),
          TriEvenements.parPlacesRestantes => (a.capacite - a.placesPrises)
              .compareTo(b.capacite - b.placesPrises),
        });
    return liste;
  }

  @override
  Widget build(BuildContext context) {
    final liste = _trierEtFiltrer(context, evenements);
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Configuration ciblée (Selector) pour C.1'),
          subtitle: Text(
            configurationCiblee
                ? 'Selector<RegistrationCart, bool> par tuile'
                : 'context.watch<RegistrationCart>() entier par tuile',
          ),
          value: configurationCiblee,
          onChanged: onBasculerConfiguration,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final event = liste[index];
              void ajouterRapide() {
                // context.read : mutation ponctuelle depuis un gestionnaire
                // d'évènement, jamais dans build.
                final resultat = context.read<RegistrationCart>().ajouter(
                      event: event,
                      session: event.sessions.first,
                      quantite: 1,
                    );
                final messages = {
                  ResultatAjout.succes: 'Ajouté au panier.',
                  ResultatAjout.dejaDansLePanier:
                      'Cet événement est déjà dans le panier.',
                  ResultatAjout.evenementComplet: 'Événement complet.',
                  ResultatAjout.plafondDepasse:
                      'Plafond de ${RegistrationCart.plafondPlaces} places atteint.',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(messages[resultat]!)),
                );
              }

              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventDetailScreen(eventId: event.id),
                  ),
                ),
                child: configurationCiblee
                    ? EventTileSelectorCible(
                        event: event,
                        onAjouterRapide: ajouterRapide,
                      )
                    : EventTileConsumerLarge(
                        event: event,
                        onAjouterRapide: ajouterRapide,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/formule.dart';
import '../routes/app_routes.dart';
import 'confirmation_screen.dart';

/// Écran de détail — version définitive (Partie C).
///
/// Le contrat PUBLIC de la route `/event-detail` est un `String id` (voir
/// `RouteGenerator._buildEventDetailRoute`) : c'est ce qui transite sur le
/// réseau conceptuel de la navigation et ce qui serait exposé par un lien
/// profond. Une fois l'identifiant validé et résolu par le générateur de
/// route, l'objet `Event` déjà résolu est passé au constructeur de ce
/// widget — cela évite de dupliquer la recherche dans le jeu de données à
/// l'intérieur de l'écran, tout en gardant le widget lui-même simple à
/// tester (il ne connaît pas la notion de "recherche par identifiant").
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _CorpsDetailEvenement(event: event),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.confirmation_number),
            label: const Text('Choisir une formule'),
            onPressed: () => _choisirFormule(context),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            // Bouton "Retour" explicite demandé par l'énoncé A.1 : un simple
            // pop, strictement équivalent à ce que fait déjà la flèche
            // automatique de l'AppBar (voir README.md pour l'explication de
            // cette flèche automatique).
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Future<void> _choisirFormule(BuildContext context) async {
    // Le type du Future est explicite (Future<Formule?>), pas de `dynamic` :
    // Navigator.pushNamed<T> est générique et infère le type de retour du
    // `pop` effectué par PackageSelectionScreen.
    final Formule? formule = await Navigator.pushNamed<Formule>(
      context,
      AppRoutes.packageSelection,
      arguments: event,
    );

    if (!context.mounted) {
      return;
    }

    if (formule == null) {
      // Cas d'annulation : l'utilisateur est revenu en arrière sans choisir.
      // L'écran de détail reste parfaitement utilisable, aucune exception,
      // aucun état partiel affiché.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélection annulée : aucune formule choisie.'),
        ),
      );
      return;
    }

    // pushReplacementNamed, jamais pushNamed : l'écran de détail est
    // remplacé par la confirmation, si bien que le retour matériel depuis la
    // confirmation ne peut plus jamais retomber sur le détail ni sur la
    // sélection (voir README.md, section pushReplacement).
    await Navigator.pushReplacementNamed(
      context,
      AppRoutes.confirmation,
      arguments: ConfirmationArgs(event: event, formule: formule),
    );
  }
}

/// Corps d'affichage partagé conceptuellement avec les écrans de
/// démonstration A.1/A.2 (`legacy_navigation_demo_screens.dart`) : même
/// contenu informatif, seule la façon d'atteindre l'écran diffère selon la
/// partie du TP démontrée.
class _CorpsDetailEvenement extends StatelessWidget {
  const _CorpsDetailEvenement({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const Icon(Icons.place, size: 18),
            const SizedBox(width: 4),
            Expanded(child: Text('${event.venue}, ${event.city}')),
          ],
        ),
        Row(
          children: <Widget>[
            const Icon(Icons.event, size: 18),
            const SizedBox(width: 4),
            Text(event.dateFormatee),
          ],
        ),
        const SizedBox(height: 8),
        Chip(label: Text(event.category)),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: event.tauxRemplissage.clamp(0, 1),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text('${event.placesPrises} / ${event.capaciteTotale} places prises'),
      ],
    );
  }
}

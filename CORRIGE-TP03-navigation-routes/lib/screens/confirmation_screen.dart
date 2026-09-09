import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/formule.dart';
import '../routes/app_routes.dart';

/// Contrat d'arguments de la route `/confirmation` 
class ConfirmationArgs {
  const ConfirmationArgs({required this.event, required this.formule});

  final Event event;
  final Formule formule;
}

/// Écran de confirmation — atteint uniquement via
/// `Navigator.pushReplacementNamed` (jamais `push`) depuis l'écran de
/// détail, une fois qu'une formule a été choisie.
///
/// Conséquence volontaire : cet écran ne comporte aucune logique
/// d'interception du retour. Le retour matériel standard suffit puisque la
/// pile ne contient plus l'écran de détail ni l'écran de sélection — ils ont
/// été remplacés, pas empilés.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.args});

  final ConfirmationArgs args;

  @override
  Widget build(BuildContext context) {
    final Event event = args.event;
    final Formule formule = args.formule;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              'Réservation confirmée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text('Événement', style: Theme.of(context).textTheme.labelLarge),
            Text('${event.title} — ${event.venue}, ${event.city}'),
            Text(event.dateFormatee),
            const SizedBox(height: 16),
            Text('Formule', style: Theme.of(context).textTheme.labelLarge),
            Text('${formule.label} — ${formule.tarifEuros.toStringAsFixed(0)} €'),
            Text(formule.description),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
                onPressed: () => _retourAccueil(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `popUntil` plutôt que `pushAndRemoveUntil` : la route d'accueil est
  /// garantie présente dans la pile (elle est la route initiale de
  /// l'application, et l'écran de confirmation n'est atteignable qu'en
  /// descendant depuis elle). `popUntil` dépile donc simplement jusqu'à elle
  /// sans la reconstruire, ce qui préserve son état (position de défilement
  /// du mur d'événements). `pushAndRemoveUntil` serait nécessaire si l'on ne
  /// pouvait pas garantir la présence de la route d'accueil dans la pile
  /// (cas de `NotFoundScreen`, qui peut être atteint depuis n'importe où).
  void _retourAccueil(BuildContext context) {
    Navigator.of(
      context,
    ).popUntil(ModalRoute.withName(AppRoutes.home));
  }
}

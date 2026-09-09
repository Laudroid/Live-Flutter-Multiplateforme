import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'event_wall_screen.dart';

/// Écran 404 générique.
///
/// Réutilisé à la fois par `onUnknownRoute` (route inconnue) et par
/// `RouteGenerator` pour les trois cas d'erreur d'arguments de
/// `/event-detail` (Partie C). Un seul widget, paramétré par [message] :
/// cela évite de dupliquer la mise en page d'un écran d'erreur pour des
/// causes différentes mais de même nature 
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
                onPressed: () => _retourAccueil(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `pushAndRemoveUntil` : on ne sait rien de la pile qui a mené jusqu'ici
  /// (route inconnue quelconque, éventuel lien profond mal formé) donc on la
  /// vide entièrement plutôt que de tenter un `popUntil` qui suppose la
  /// présence de la route d'accueil dans la pile.
  void _retourAccueil(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.home),
        builder: (_) => const EventWallScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }
}

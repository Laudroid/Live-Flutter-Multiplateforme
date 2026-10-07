import 'package:flutter/material.dart';

/// Écran affiché lorsque `Firebase.initializeApp` a échoué au démarrage.
///
/// Exigence de l'énoncé (Partie A.6) : l'application doit démarrer sur un
/// écran d'erreur explicite plutôt que de laisser planter le widget racine.
/// Cet écran ne tente aucune action Firebase (elle échouerait de la même
/// façon) : il se contente d'expliquer la situation et de rappeler la
/// procédure de remise en route, ce qui est la seule action utile tant que
/// `lib/firebase_options.dart` n'a pas été régénéré avec de vraies valeurs.
class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  'Impossible d\'initialiser Firebase',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'L\'application n\'a pas pu se connecter à Firebase. '
                  'C\'est attendu si lib/firebase_options.dart contient '
                  'encore des valeurs fictives : régénérez ce fichier avec '
                  '`flutterfire configure` puis relancez l\'application.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

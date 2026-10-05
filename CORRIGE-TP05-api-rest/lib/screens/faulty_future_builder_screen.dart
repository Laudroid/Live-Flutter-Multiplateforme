import 'package:flutter/material.dart';

import '../api/users_api.dart';
import 'request_log_screen.dart';

/// Démonstration volontaire du piège central de la partie C : cet écran
/// contient DEUX widgets internes qui sollicitent la même API de deux
/// façons différentes, pour rendre le défaut observable dans le journal
/// des requêtes (icône en haut à droite de DirectoryScreen) plutôt que de
/// se contenter de l'expliquer en commentaire.
///
/// Le bouton « provoquer une recomposition » déclenche un `setState` sur
/// CET écran, sans aucun rapport avec les données affichées (l'équivalent
/// d'une rotation d'écran ou de l'ouverture du clavier). Observez le
/// journal des requêtes après plusieurs appuis :
/// - le panneau « FAUTIF » réémet une requête GET à chaque appui ;
/// - le panneau « CORRIGÉ » n'en émet aucune (son Future a été mémorisé
///   dans initState et n'est jamais recréé par build).
class FaultyFutureBuilderDemoScreen extends StatefulWidget {
  const FaultyFutureBuilderDemoScreen({super.key, required this.api});

  final UsersApi api;

  @override
  State<FaultyFutureBuilderDemoScreen> createState() =>
      _FaultyFutureBuilderDemoScreenState();
}

class _FaultyFutureBuilderDemoScreenState
    extends State<FaultyFutureBuilderDemoScreen> {
  int _compteurRecompositions = 0;

  // Version corrigée : mémorisée une seule fois.
  late Future<UsersPage> _futureCorrige;

  @override
  void initState() {
    super.initState();
    _futureCorrige = widget.api.fetchFirstPageForDemo();
  }

  void _provoquerRecomposition() {
    setState(() => _compteurRecompositions += 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Démo — piège du FutureBuilder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recompositions provoquées : $_compteurRecompositions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _provoquerRecomposition,
              child: const Text(
                'Provoquer une recomposition (setState sans rapport '
                'avec les données)',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('Ouvrir le journal des requêtes'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RequestLogScreen()),
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _Panneau(
                      titre: 'FAUTIF',
                      sousTitre:
                          'future: widget.api.fetchFirstPageForDemo() '
                          'écrit directement dans build()',
                      couleur: Colors.red,
                      // Volontairement fautif : l'appel est fait ICI, dans
                      // build(), donc à chaque recomposition de cet écran
                      // — y compris lors de l'appui sur le bouton ci-dessus,
                      // qui ne concerne pourtant pas ces données.
                      // ignore_for_file n'est pas utilisé : ce défaut doit
                      // rester visible à la lecture du code, pas masqué.
                      future: widget.api.fetchFirstPageForDemo(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Panneau(
                      titre: 'CORRIGÉ',
                      sousTitre:
                          'future mémorisé dans initState, jamais '
                          'recréé par build',
                      couleur: Colors.green,
                      future: _futureCorrige,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panneau extends StatelessWidget {
  const _Panneau({
    required this.titre,
    required this.sousTitre,
    required this.couleur,
    required this.future,
  });

  final String titre;
  final String sousTitre;
  final Color couleur;
  final Future<UsersPage> future;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: couleur.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: TextStyle(fontWeight: FontWeight.bold, color: couleur)),
          Text(sousTitre, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FutureBuilder<UsersPage>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return const Text('Erreur.');
              }
              final nb = snapshot.data?.participants.length ?? 0;
              return Text('$nb participants reçus.\nVoir le journal pour le nombre de GET émis.');
            },
          ),
        ],
      ),
    );
  }
}

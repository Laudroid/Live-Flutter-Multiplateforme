import 'package:flutter/material.dart';

import '../api/users_api.dart';

/// Affiche le journal des requêtes émises par [UsersApi], horodaté.
/// C'est l'outil d'observation demandé par la partie C et par le README :
/// il rend visible, sans dépendre de la console, le nombre d'appels réels
/// (piège du FutureBuilder recréé) et l'espacement des nouvelles tentatives
/// (backoff croissant sur `/http/500`).
class RequestLogScreen extends StatefulWidget {
  const RequestLogScreen({super.key});

  @override
  State<RequestLogScreen> createState() => _RequestLogScreenState();
}

class _RequestLogScreenState extends State<RequestLogScreen> {
  @override
  Widget build(BuildContext context) {
    final lignes = UsersApi.requestLog;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal des requêtes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir l\'affichage du journal',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Vider le journal',
            onPressed: () => setState(UsersApi.requestLog.clear),
          ),
        ],
      ),
      body: lignes.isEmpty
          ? const Center(child: Text('Aucune requête émise pour le moment.'))
          : ListView.builder(
              itemCount: lignes.length,
              itemBuilder: (context, index) {
                // Affiché du plus récent au plus ancien pour repérer
                // immédiatement une rafale de requêtes.
                final ligne = lignes[lignes.length - 1 - index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    ligne,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}

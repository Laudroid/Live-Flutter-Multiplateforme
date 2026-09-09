import 'package:flutter/material.dart';

import 'demo_callback_screen.dart';
import 'demo_change_notifier_screen.dart';
import 'event_list_screen.dart';

/// Écran d'accueil du corrigé : donne accès aux deux démonstrations de la
/// Partie A côte à côte, puis à l'application réelle des Parties B et C.
/// Cet écran ne détient et ne consomme aucun état global : il ne fait que
/// naviguer.
class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corrigé TP4 — Provider')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Partie A — comparaison AVANT / APRÈS',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EventListScreenCallbacks(),
              ),
            ),
            child: const Text('AVANT — setState + callbacks (A.1)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventListScreenAfter()),
            ),
            child: const Text('APRÈS — ChangeNotifier (A.3)'),
          ),
          const Divider(height: 32),
          Text(
            'Parties B et C — application réelle',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventListScreen()),
            ),
            child: const Text('Panier complet (B) + recomposition/injection (C)'),
          ),
        ],
      ),
    );
  }
}

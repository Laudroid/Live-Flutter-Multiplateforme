import 'package:flutter/material.dart';

import 'screens/event_creation_screen.dart';
import 'screens/registration_screen.dart';

void main() {
  runApp(const EventPlannerFormsApp());
}

class EventPlannerFormsApp extends StatelessWidget {
  const EventPlannerFormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner — Formulaires',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Écran d'accueil minimal : la navigation n'est pas évaluée dans ce TP (elle
/// relève de la séance 3), on se contente donc de deux points d'entrée
/// simples vers les deux formulaires du corrigé.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Planner — TP 6')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              ),
              child: const Text('Partie A — Formulaire d\'inscription'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventCreationScreen()),
              ),
              child: const Text('Partie B/C — Créer un événement'),
            ),
          ],
        ),
      ),
    );
  }
}

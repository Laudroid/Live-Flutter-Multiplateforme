import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/event_repository.dart';
import 'screens/home_menu_screen.dart';
import 'state/demo_counter.dart';
import 'state/display_preferences.dart';
import 'state/event_list_notifier.dart';
import 'state/registration_cart.dart';

void main() {
  runApp(const EventPlannerApp());
}

/// Racine de l'application. Tous les providers globaux sont assemblés ICI,
/// au-dessus de `MaterialApp`, conformément à l'énoncé (A.3.2 et B.4) :
/// c'est ce qui permet à l'état de survivre à n'importe quelle navigation
/// interne au `Navigator` du `MaterialApp`, puisque le `Navigator` est un
/// descendant des providers, jamais l'inverse.
///
/// `EventRepository` est fourni par un `Provider` simple (donnée immuable,
/// pas de notification nécessaire) et injecté dans `RegistrationCart` et
/// `EventListNotifier` via `ChangeNotifierProxyProvider` (Partie C.3) :
/// aucun des deux notifiers ne construit son propre dépôt.
class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Démonstration Partie A.3 uniquement — voir state/demo_counter.dart.
        ChangeNotifierProvider(create: (_) => DemoCounterNotifier()),

        // Dépôt de données en dur, sans état, fourni une seule fois.
        Provider<EventRepository>(create: (_) => const EventRepository()),

        // Partie B.3 : préférences d'affichage, notifier indépendant.
        ChangeNotifierProvider(create: (_) => DisplayPreferences()),

        // Partie B.2/C.3 : panier, dépôt injecté plutôt qu'instancié en dur.
        ChangeNotifierProxyProvider<EventRepository, RegistrationCart>(
          create: (context) =>
              RegistrationCart(depot: context.read<EventRepository>()),
          update: (context, repository, previousCart) =>
              previousCart!..updateRepository(repository),
        ),

        // Partie C.4 : chargement de la liste, machine à états scellée.
        ChangeNotifierProxyProvider<EventRepository, EventListNotifier>(
          create: (context) =>
              EventListNotifier(depot: context.read<EventRepository>()),
          update: (context, repository, previousNotifier) =>
              previousNotifier!..updateRepository(repository),
        ),
      ],
      child: MaterialApp(
        title: 'Corrigé TP4 — Provider',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
        home: const HomeMenuScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'screens/event_wall_screen.dart';

void main() {
  runApp(const EventPlannerApp());
}

/// Point d'entrée minimal : un `MaterialApp` pointant directement sur
/// l'écran du mur d'événements. Aucun `Navigator` ni route nommée n'est
/// nécessaire pour ce TP : `home` suffit.
class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const EventWallScreen(),
    );
  }
}

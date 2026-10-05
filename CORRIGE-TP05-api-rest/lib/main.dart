import 'package:flutter/material.dart';

import 'screens/directory_screen.dart';

void main() {
  runApp(const EventPlannerApiApp());
}

class EventPlannerApiApp extends StatelessWidget {
  const EventPlannerApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner — Annuaire API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DirectoryScreen(),
    );
  }
}

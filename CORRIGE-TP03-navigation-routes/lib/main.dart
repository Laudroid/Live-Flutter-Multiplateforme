import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'screens/event_wall_screen.dart';
import 'screens/legacy_navigation_demo_screens.dart';

void main() {
  runApp(const CorrigeTp03App());
}

/// Point d'entrée de l'application — corrigé de référence du TP 3.
///
/// La table de routes est volontairement scindée en deux mécanismes,
/// démontrant la progression pédagogique du TP :
/// - `routes:` : routes statiques sans argument dynamique (`home`) ou dont
///   l'argument est relu manuellement via `ModalRoute` (démonstration A.2) ;
/// - `onGenerateRoute` / `onUnknownRoute` : toutes les routes dynamiques de
///   production, avec extraction et validation centralisées des arguments
///   (Partie C).
class CorrigeTp03App extends StatelessWidget {
  const CorrigeTp03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corrigé TP3 — Navigation et routes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      routes: <String, WidgetBuilder>{
        AppRoutes.home: (BuildContext context) => const EventWallScreen(),
        // PARTIE A.2 — démonstration conservée : route nommée déclarée dans
        // la table statique `routes:`. L'objet Event est récupéré à
        // l'intérieur de l'écran via
        // `ModalRoute.of(context)!.settings.arguments`.
        AppRoutes.eventDetailNamedArgsDemo: (BuildContext context) =>
            const EventDetailNamedArgsDemoScreen(),
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}

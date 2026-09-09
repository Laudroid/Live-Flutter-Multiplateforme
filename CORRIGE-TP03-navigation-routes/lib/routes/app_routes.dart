import 'package:flutter/material.dart';

import 'route_generator.dart';

/// Table de routes centralisée : toute chaîne de nom de route de
/// l'application est une constante déclarée ici, jamais une chaîne littérale
/// ailleurs dans le code (critère de réussite de la Partie A.2).
abstract final class AppRoutes {
  /// Mur d'événements — écran d'accueil, déclaré dans la table `routes:`
  /// statique du `MaterialApp` (aucun argument).
  static const String home = '/';
  static const String eventDetail = '/event-detail';
  static const String packageSelection = '/package-selection';

  /// Écran de confirmation — Partie B. Atteint uniquement par
  /// `pushReplacementNamed` depuis l'écran de détail, jamais par `push`.
  static const String confirmation = '/confirmation';

  /// Fonctions déléguées à [RouteGenerator] : `app_routes.dart` reste le
  /// point d'entrée unique référencé par `main.dart`
  static Route<dynamic> onGenerateRoute(RouteSettings settings) =>
      RouteGenerator.generate(settings);

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      RouteGenerator.buildUnknownRoute(settings);
}

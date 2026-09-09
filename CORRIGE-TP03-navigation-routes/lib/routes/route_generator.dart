import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../models/event.dart';
import '../screens/confirmation_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/package_selection_screen.dart';
import 'app_routes.dart';

/// Fonction de génération de route centralisée (Partie C).
///
/// Chaque route dynamique de l'application passe par ici : les arguments
/// reçus via [RouteSettings.arguments] sont extraits et validés avant de
/// construire l'écran. Aucun `as Event` ni `as String` non gardé n'est fait
/// dans les écrans eux-mêmes pour les routes concernées par ce fichier.
abstract final class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.eventDetail:
        return _buildEventDetailRoute(settings);
      case AppRoutes.packageSelection:
        return _buildPackageSelectionRoute(settings);
      case AppRoutes.confirmation:
        return _buildConfirmationRoute(settings);
      default:
        // Un nom de route non reconnu par ce switch (mais tout de même
        // déclaré quelque part, ou fautif) tombe ici. `onUnknownRoute` ne
        // sera consulté par le Navigator que si NI `routes:` NI
        // `onGenerateRoute` ne renvoient de route ; en renvoyant nous-mêmes
        // un écran 404 ici, on couvre aussi le cas d'un nom de route inconnu
        // simplement passé à `onGenerateRoute`.
        return buildUnknownRoute(settings);
    }
  }

  /// Écran 404 générique, utilisé aussi bien par `onUnknownRoute` que par ce
  /// fichier lorsqu'un nom de route ne correspond à rien.
  static Route<dynamic> buildUnknownRoute(RouteSettings settings) {
    return _errorRoute(
      'Aucun écran n\'est enregistré pour la route « ${settings.name} ».',
    );
  }

  // --- /event-detail ------------------------------------------------------
  //
  // Partie C, point 2 : trois cas d'erreur distincts sur les arguments,
  // chacun redirigé vers l'écran 404 réutilisé avec un message dédié plutôt
  // que de laisser une exception non interceptée remonter jusqu'au
  // framework (ce qui produirait un écran rouge "FlutterError").
  static Route<dynamic> _buildEventDetailRoute(RouteSettings settings) {
    final Object? args = settings.arguments;

    // Cas 1 : arguments absents.
    if (args == null) {
      return _errorRoute(
        'Arguments manquants pour la route "${AppRoutes.eventDetail}" : '
        'un identifiant d\'événement (String) est requis.',
      );
    }

    // Cas 2 : type inattendu (par exemple un Event complet ou une Map,
    // au lieu du String attendu par le contrat de cette route).
    if (args is! String) {
      return _errorRoute(
        'Type d\'argument inattendu pour "${AppRoutes.eventDetail}" : '
        'un String était attendu, ${args.runtimeType} a été reçu.',
      );
    }

    // Cas 3 : identifiant syntaxiquement valide mais absent du jeu de
    // données.
    final Event? event = _trouverEvenement(args);
    if (event == null) {
      return _errorRoute(
        'Aucun événement ne correspond à l\'identifiant "$args".',
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => EventDetailScreen(event: event),
    );
  }

  static Event? _trouverEvenement(String id) {
    for (final Event event in sampleEvents) {
      if (event.id == id) {
        return event;
      }
    }
    return null;
  }

  // --- /package-selection --------------------------------------------------
  static Route<dynamic> _buildPackageSelectionRoute(RouteSettings settings) {
    final Object? args = settings.arguments;
    if (args is! Event) {
      return _errorRoute(
        'Type d\'argument inattendu pour "${AppRoutes.packageSelection}" : '
        'un Event était attendu, ${args.runtimeType} a été reçu.',
      );
    }
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => PackageSelectionScreen(event: args),
    );
  }

  // --- /confirmation ---------------------------------------------------------
  static Route<dynamic> _buildConfirmationRoute(RouteSettings settings) {
    final Object? args = settings.arguments;
    if (args is! ConfirmationArgs) {
      return _errorRoute(
        'Type d\'argument inattendu pour "${AppRoutes.confirmation}" : '
        'un ConfirmationArgs était attendu, ${args.runtimeType} a été reçu.',
      );
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => ConfirmationScreen(args: args),
    );
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute<void>(
      builder: (_) => NotFoundScreen(message: message),
    );
  }
}

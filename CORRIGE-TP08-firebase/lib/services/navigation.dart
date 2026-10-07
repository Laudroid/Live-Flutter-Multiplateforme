import 'package:flutter/material.dart';

/// Clé de navigation racine, partagée entre `main.dart` (qui la passe à
/// `MaterialApp.navigatorKey`) et les écrans qui doivent purger la pile de
/// navigation lors de la déconnexion (Partie B.5).
///
/// Pourquoi une clé globale plutôt qu'un `Navigator.of(context)` local :
/// [AuthGate] est placé en `home` de `MaterialApp`, donc tout écran poussé
/// par-dessus (ProfileScreen, RegisterScreen...) se trouve plus haut dans la
/// pile. Un `Navigator.of(context).pushAndRemoveUntil` déclenché depuis un
/// de ces écrans ne connaît que sa propre position ; `popUntil((route) =>
/// route.isFirst)` sur la clé racine revient systématiquement jusqu'à la
/// toute première route (celle d'AuthGate), quel que soit l'écran depuis
/// lequel la déconnexion a été demandée. C'est ce qui garantit qu'aucun
/// bouton retour ne peut ensuite révéler un écran de l'espace organisateur.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

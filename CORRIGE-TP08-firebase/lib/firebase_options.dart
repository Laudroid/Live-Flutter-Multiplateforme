// ATTENTION — FICHIER FICTIF, À REMPLACER AVANT TOUT LANCEMENT RÉEL
// ============================================================================
// Ce fichier n'est PAS un fichier généré par `flutterfire configure`. Il a été
// écrit à la main pour ce corrigé, uniquement pour que le projet compile et
// que `flutter analyze` passe sans erreur, car `main.dart` importe
// `DefaultFirebaseOptions` et le projet ne s'analyse pas sans cette classe.
//
// Toutes les valeurs ci-dessous (apiKey, appId, projectId, etc.) sont des
// chaînes fictives et ne désignent AUCUN projet Firebase réel. L'application
// démarrera, affichera son écran d'erreur d'initialisation (voir main.dart),
// mais aucun appel Auth ou Firestore ne pourra jamais réussir tant que ce
// fichier n'a pas été régénéré.
//
// Procédure pour rendre ce projet fonctionnel :
//   1. Créer un projet sur https://console.firebase.google.com (plan Spark).
//   2. npm install -g firebase-tools && firebase login
//   3. dart pub global activate flutterfire_cli
//   4. Depuis la racine de CE projet Flutter : flutterfire configure
//      -> sélectionner le projet créé à l'étape 1, cocher au moins Android.
//   5. flutterfire configure ÉCRASE ce fichier avec les vraies valeurs.
//      C'est le comportement attendu : ne le restaurez pas depuis git après.
//
// Tant que ce fichier contient les valeurs "REMPLACER-PAR-..." ci-dessous,
// Firebase.initializeApp() lèvera une exception interceptée par main.dart
// et l'utilisateur verra l'écran d'erreur d'initialisation, pas un plantage.
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options de configuration Firebase par plateforme.
///
/// Fichier normalement généré automatiquement par la commande
/// `flutterfire configure`. Voir l'avertissement en tête de fichier :
/// ces valeurs sont fictives et doivent être remplacées.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne sont pas configurées pour cette '
          'plateforme. Régénérez ce fichier avec `flutterfire configure` '
          'en cochant la plateforme voulue.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REMPLACER-PAR-VOTRE-API-KEY',
    appId: 'REMPLACER-PAR-VOTRE-APP-ID-WEB',
    messagingSenderId: 'REMPLACER-PAR-VOTRE-SENDER-ID',
    projectId: 'REMPLACER-PAR-VOTRE-PROJECT-ID',
    authDomain: 'REMPLACER-PAR-VOTRE-PROJET.firebaseapp.com',
    storageBucket: 'REMPLACER-PAR-VOTRE-PROJET.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REMPLACER-PAR-VOTRE-API-KEY',
    appId: 'REMPLACER-PAR-VOTRE-APP-ID-ANDROID',
    messagingSenderId: 'REMPLACER-PAR-VOTRE-SENDER-ID',
    projectId: 'REMPLACER-PAR-VOTRE-PROJECT-ID',
    storageBucket: 'REMPLACER-PAR-VOTRE-PROJET.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACER-PAR-VOTRE-API-KEY',
    appId: 'REMPLACER-PAR-VOTRE-APP-ID-IOS',
    messagingSenderId: 'REMPLACER-PAR-VOTRE-SENDER-ID',
    projectId: 'REMPLACER-PAR-VOTRE-PROJECT-ID',
    storageBucket: 'REMPLACER-PAR-VOTRE-PROJET.appspot.com',
    iosBundleId: 'com.example.corrigeTp08Firebase',
  );
}

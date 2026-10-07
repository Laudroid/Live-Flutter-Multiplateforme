import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/initialization_error_screen.dart';
import 'services/app_config.dart';
import 'services/auth_gate.dart';
import 'services/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Partie D — bascule vers les émulateurs Firebase locaux. Le drapeau
    // useFirebaseEmulators (lib/services/app_config.dart) permet de changer
    // de cible sans dupliquer le code de l'application : voir CORRIGE.md,
    // section "Partie D — esquisse", pour la note pédagogique sur l'intérêt
    // des émulateurs. Cet appel doit précéder tout autre usage d'Auth ou de
    // Firestore, comme l'exige la documentation FlutterFire.
    if (useFirebaseEmulators) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    }

    runApp(const EventPlannerApp());
  } catch (error) {
    // Exigence Partie A.6 : un échec de Firebase.initializeApp ne doit
    // jamais planter silencieusement l'application. C'est le cas par
    // défaut de ce corrigé tant que lib/firebase_options.dart contient des
    // valeurs fictives (voir l'avertissement en tête de ce fichier) :
    // l'utilisateur voit un écran d'erreur exploitable.
    runApp(InitializationErrorScreen(error: error));
  }
}

class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner — espace organisateur',
      debugShowCheckedModeBanner: false,
      // Clé de navigation racine : voir lib/services/navigation.dart pour
      // la raison (purge complète de la pile lors de la déconnexion,
      // Partie B.5).
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // AuthGate est l'unique route de départ : voir services/auth_gate.dart
      // pour la justification de la garde d'accès (Partie B.4).
      home: const AuthGate(),
    );
  }
}

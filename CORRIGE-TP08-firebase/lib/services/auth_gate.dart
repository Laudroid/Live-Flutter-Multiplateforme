import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/organizer_home_screen.dart';

/// Garde d'accès de l'application.
///
/// Exigence de l'énoncé (Partie B.4) : les écrans de l'espace organisateur
/// doivent être *structurellement inatteignables* sans session valide, et
/// cette garde doit s'appuyer exclusivement sur un `StreamBuilder` écoutant
/// `authStateChanges()` à la racine de la navigation — pas sur un état
/// global maison (`provider`, `ChangeNotifier`...) qui dupliquerait cette
/// information et pourrait se désynchroniser du SDK.
///
/// Ce widget est placé comme `home` de `MaterialApp` : il n'existe donc
/// aucune route qui mène à [OrganizerHomeScreen] sans passer par ce
/// `StreamBuilder`, ce qui satisfait l'exigence "structurellement
/// inatteignable" (par opposition à un simple `if (connecté) ... else ...`
/// dans un widget qu'on pourrait contourner en changeant de route).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // En attente du premier événement : c'est ce court instant qui
        // permet la restauration automatique de session au redémarrage
        // (Partie B.4) sans afficher furtivement l'écran de connexion.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        return const OrganizerHomeScreen();
      },
    );
  }
}

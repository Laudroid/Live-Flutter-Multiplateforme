import 'package:firebase_auth/firebase_auth.dart';

/// Vue minimale, propre à l'application, d'un utilisateur Firebase Auth.
///
/// On ne stocke pas l'objet [User] du SDK directement dans les écrans : cette
/// petite enveloppe évite de propager une dépendance forte au SDK dans toute
/// l'interface, et documente explicitement les champs dont l'application a
/// réellement besoin.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
  });

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }
}

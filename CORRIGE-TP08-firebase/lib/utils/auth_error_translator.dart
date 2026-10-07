import 'package:firebase_auth/firebase_auth.dart';

/// Traduit une [FirebaseAuthException] en message français exploitable par un
/// utilisateur non technique.
///
/// Il est formellement interdit d'afficher `e.message` ou `e.toString()`
/// bruts à l'utilisateur (voir énoncé Partie B) : ce message contient parfois
/// des détails techniques (nom du SDK, code HTTP) sans valeur pour lui, et
/// change de formulation entre deux versions du SDK sans préavis, ce qui
/// rendrait toute interface utilisateur qui s'appuierait dessus fragile.
///
/// Les codes ci-dessous sont vérifiés contre la documentation intégrée au
/// paquet `firebase_auth` 6.6.1 installé dans ce projet
/// (lib/src/firebase_auth.dart), pas contre une mémoire d'entraînement qui
/// peut dater d'une version antérieure de l'API.
String translateAuthError(FirebaseAuthException exception) {
  switch (exception.code) {
    case 'email-already-in-use':
      return 'Un compte existe déjà avec cette adresse courriel. '
          'Essayez de vous connecter, ou réinitialisez votre mot de passe.';
    case 'invalid-email':
      return 'Cette adresse courriel n\'est pas valide. Vérifiez sa saisie.';
    case 'weak-password':
      return 'Ce mot de passe est trop faible. Utilisez au moins 6 '
          'caractères, en mélangeant idéalement lettres et chiffres.';
    case 'invalid-credential':
    case 'wrong-password':
      // 'wrong-password' est marqué obsolète par le SDK (remplacé par
      // 'invalid-credential') mais certains chemins de code peuvent encore
      // le renvoyer selon la configuration du projet : on couvre les deux.
      return 'Adresse courriel ou mot de passe incorrect.';
    case 'too-many-requests':
      return 'Trop de tentatives ont été effectuées. Patientez quelques '
          'minutes avant de réessayer.';
    case 'operation-not-allowed':
      return 'La connexion par courriel et mot de passe n\'est pas activée '
          'pour cette application. Contactez l\'administrateur.';
    case 'user-disabled':
      return 'Ce compte a été désactivé. Contactez l\'administrateur.';
    case 'user-not-found':
      return 'Aucun compte ne correspond à cette adresse courriel.';
    case 'network-request-failed':
      return 'Impossible de contacter le serveur. Vérifiez votre connexion '
          'internet et réessayez.';
    default:
      return 'Une erreur inattendue est survenue. Veuillez réessayer.';
  }
}

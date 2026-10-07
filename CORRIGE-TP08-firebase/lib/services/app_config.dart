/// Drapeau de basculement vers les émulateurs Firebase locaux (Partie D).
///
/// Volontairement une constante compilée plutôt qu'une variable lue au
/// lancement : l'énoncé demande un "drapeau de configuration (constante
/// booléenne ou variable d'environnement)" pour éviter de dupliquer le code
/// entre un chemin "production" et un chemin "émulateurs". Ici on choisit la
/// forme la plus simple à faire varier en séance : passer
/// `--dart-define=USE_FIREBASE_EMULATORS=true` à `flutter run`, ou changer
/// la valeur par défaut ci-dessous pour un test rapide.
///
/// Partie D — esquisse : ce drapeau, une fois activé, doit être exploité
/// avant tout autre appel Firebase (voir main.dart) pour rediriger Auth et
/// Firestore vers `localhost`. Le reste de la Partie D (note pédagogique sur
/// l'intérêt des émulateurs pour la reproductibilité d'une formation et pour
/// les tests automatisés) n'est volontairement pas développé ici : voir
/// CORRIGE.md, section "Partie D — esquisse".
const bool useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

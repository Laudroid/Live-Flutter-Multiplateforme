/// Compteurs de reconstruction pour la démonstration « avant » (callbacks,
/// Partie A.1). Des entiers statiques, remis à zéro au lancement de
/// l'écran de démonstration, permettent d'afficher à l'écran le nombre
/// d'appels à `build` de chaque widget de la chaîne de callbacks — c'est le
/// tableau chiffré exigé par l'énoncé (A.1.4), pas une estimation.
class CompteursDemoAvant {
  static int eventTile = 0;
  static int eventSection = 0;
  static int cartBadge = 0;

  static void remettreAZero() {
    eventTile = 0;
    eventSection = 0;
    cartBadge = 0;
  }
}

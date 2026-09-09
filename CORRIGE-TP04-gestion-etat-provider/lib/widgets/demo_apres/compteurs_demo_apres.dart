/// Équivalent de `CompteursDemoAvant` pour la démonstration « après »
/// (Partie A.3, `DemoCounterNotifier`).
class CompteursDemoApres {
  static int eventTile = 0;
  static int eventSection = 0;
  static int cartBadge = 0;

  static void remettreAZero() {
    eventTile = 0;
    eventSection = 0;
    cartBadge = 0;
  }
}

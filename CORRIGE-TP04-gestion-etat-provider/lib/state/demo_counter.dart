import 'package:flutter/foundation.dart';

/// Notifier minimal utilisé UNIQUEMENT par l'écran de démonstration
/// « après » (Partie A.3), pour reproduire à l'identique l'exemple de
/// l'énoncé et permettre une comparaison à opération strictement égale avec
/// la démonstration « avant » (callbacks). Il ne fait pas partie de
/// l'architecture finale de l'application : `RegistrationCart` est le seul
/// notifier utilisé par les écrans réels du panier (Parties B et C).
class DemoCounterNotifier extends ChangeNotifier {
  int get count => _count;
  int _count = 0;

  void increment() {
    _count++;
    notifyListeners();
  }
}

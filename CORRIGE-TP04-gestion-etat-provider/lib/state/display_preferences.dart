// Même contrainte de découplage que registration_cart.dart : aucun paquet
// de widgets Flutter, uniquement `foundation.dart`.
import 'package:flutter/foundation.dart';

/// Critère de tri de la liste d'événements.
enum TriEvenements { parTitre, parPlacesRestantes }

/// Densité d'affichage de la liste (réemploi de la notion vue au TP 2).
enum DensiteAffichage { confortable, compacte }

/// Second notifier indépendant : aucune dépendance envers `RegistrationCart`
/// (ni import, ni référence), afin de bien montrer que deux préoccupations
/// globales distinctes peuvent vivre dans deux notifiers séparés et être
/// combinées uniquement au moment de l'assemblage (`MultiProvider`), pas
/// couplées entre elles au niveau du code métier.
class DisplayPreferences extends ChangeNotifier {
  TriEvenements _tri = TriEvenements.parTitre;
  String? _categorieFiltre;
  DensiteAffichage _densite = DensiteAffichage.confortable;

  TriEvenements get tri => _tri;
  String? get categorieFiltre => _categorieFiltre;
  DensiteAffichage get densite => _densite;

  void changerTri(TriEvenements nouveauTri) {
    if (nouveauTri == _tri) return;
    _tri = nouveauTri;
    notifyListeners();
  }

  /// `null` signifie « aucun filtre, tout afficher ».
  void filtrerParCategorie(String? categorie) {
    if (categorie == _categorieFiltre) return;
    _categorieFiltre = categorie;
    notifyListeners();
  }

  void changerDensite(DensiteAffichage nouvelleDensite) {
    if (nouvelleDensite == _densite) return;
    _densite = nouvelleDensite;
    notifyListeners();
  }
}

import 'package:flutter/services.dart';

/// Limite la saisie du champ tarif à deux décimales au maximum après le
/// séparateur (le point). N'empêche pas la saisie de la partie entière, quel
/// que soit sa longueur, et n'empêche pas non plus d'éditer au milieu de la
/// valeur (le formatteur ne fait que refuser les modifications qui
/// produiraient une troisième décimale, il ne réécrit jamais la position du
/// curseur au-delà de ce que Flutter calcule automatiquement).
class TwoDecimalsFormatter extends TextInputFormatter {
  // Autorise : rien, des chiffres seuls, ou des chiffres suivis d'un point et
  // d'au plus deux chiffres.
  static final RegExp _motifAutorise = RegExp(r'^\d*(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (_motifAutorise.hasMatch(newValue.text)) {
      return newValue;
    }
    // La frappe produirait une troisième décimale (ou un caractère invalide) :
    // on rejette la modification et on conserve l'ancienne valeur, y compris
    // sa position de curseur.
    return oldValue;
  }
}

// Règles de validation croisée : elles portent sur plusieurs champs à la
// fois et ne peuvent donc pas être exprimées dans le `validator` d'un champ
// isolé. Couche PURE : aucun import de package:flutter/*. On utilise
// uniquement des types Dart de base (DateTime, num, bool, String).
//
// Chaque fonction retourne null si la règle est respectée, ou un message
// d'erreur en français orienté "action corrective" sinon.

/// Règle 1 : la date de fin doit être strictement postérieure à la date de
/// début. Si l'une des deux dates n'est pas encore renseignée, la règle ne
/// peut pas être évaluée : on ne lève pas d'exception, on retourne un message
/// adapté qui guide l'utilisateur, sans jamais planter le formulaire.
String? validerDateFinApresDebut({
  required DateTime? dateDebut,
  required DateTime? dateFin,
}) {
  if (dateDebut == null) {
    return 'Choisissez d\'abord une date de début.';
  }
  if (dateFin == null) {
    return 'Choisissez une date de fin.';
  }
  if (!dateFin.isAfter(dateDebut)) {
    return 'La date de fin doit être postérieure à la date de début.';
  }
  return null;
}

/// Règle 2 : l'adresse est obligatoire si l'événement n'est pas en ligne, et
/// interdite (doit rester vide) s'il est en ligne.
String? validerAdresseSelonModalite({
  required bool estEnLigne,
  required String adresse,
}) {
  final String texte = adresse.trim();
  if (estEnLigne && texte.isNotEmpty) {
    return 'Événement en ligne : videz le champ adresse, il n\'est pas utilisé.';
  }
  if (!estEnLigne && texte.isEmpty) {
    return 'Événement en présentiel : saisissez l\'adresse du lieu.';
  }
  return null;
}

/// Règle 3 : le tarif doit être nul (0 ou champ vide, par convention
/// explicite : les deux sont acceptés comme "gratuit") si la case "événement
/// gratuit" est cochée. On ne corrige jamais silencieusement la saisie : on
/// signale l'incohérence à l'utilisateur, qui reste maître de son choix.
String? validerTarifSelonGratuite({
  required bool estGratuit,
  required String tarifSaisi,
}) {
  if (!estGratuit) return null;
  final String texte = tarifSaisi.trim();
  if (texte.isEmpty) return null;
  final double? valeur = double.tryParse(texte);
  if (valeur == null) {
    // Une valeur non numérique sera de toute façon rejetée par le validateur
    // élémentaire du champ ; on ne double pas le message ici.
    return null;
  }
  if (valeur != 0) {
    return 'Événement gratuit : le tarif doit être 0 ou laissé vide.';
  }
  return null;
}

/// Règle 4 : la capacité doit rester supérieure ou égale au nombre
/// d'inscrits déjà enregistrés pour cet événement.
String? validerCapaciteSuffisante({
  required int? capacite,
  required int inscritsExistants,
}) {
  if (capacite == null) {
    return 'Saisissez la capacité maximale.';
  }
  if (capacite < inscritsExistants) {
    return 'La capacité ne peut pas être inférieure au nombre d\'inscrits '
        'déjà enregistrés ($inscritsExistants). Augmentez la capacité.';
  }
  return null;
}

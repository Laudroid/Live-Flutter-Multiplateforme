// Couche de validation PURE : aucun import de package:flutter/* dans ce fichier.
// Chaque fonction retourne un `Validator`, c'est-à-dire une fonction qui prend
// la valeur du champ (String? tel que le fournit un TextFormField) et retourne
// soit null (valeur acceptée), soit un message d'erreur en français destiné à
// l'utilisateur final.
//
// Ces règles sont volontairement à granularité fine (une responsabilité par
// fonction) pour pouvoir être composées avec `compose` et testées isolément,
// sans dépendre d'un widget ni d'un BuildContext.

typedef Validator = String? Function(String? value);

/// Le champ ne doit pas être vide (après suppression des espaces de bord).
Validator requiredField({String message = 'Ce champ est obligatoire.'}) {
  return (String? value) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  };
}

/// Longueur minimale, évaluée sur la valeur "trimmée".
/// Ne s'applique pas si le champ est vide : c'est le rôle de `required` de le
/// signaler, pour ne pas cumuler deux messages contradictoires sur un champ
/// vide et optionnel.
Validator minLength(int min, {String Function(int)? message}) {
  return (String? value) {
    final String texte = (value ?? '').trim();
    if (texte.isEmpty) return null;
    if (texte.length < min) {
      return message != null
          ? message(min)
          : 'Saisissez au moins $min caractères.';
    }
    return null;
  };
}

/// Longueur maximale, évaluée sur la valeur "trimmée".
Validator maxLength(int max, {String Function(int)? message}) {
  return (String? value) {
    final String texte = (value ?? '').trim();
    if (texte.length > max) {
      return message != null
          ? message(max)
          : 'Ne dépassez pas $max caractères.';
    }
    return null;
  };
}

/// La valeur doit correspondre intégralement au motif fourni.
/// Ne s'applique pas si le champ est vide (déléguer ce cas à `requiredField`).
///
/// Attention : contrairement à `minLength`/`maxLength`, on ne valide PAS la
/// valeur "trimmée" mais la valeur brute. Un test réel a démontré qu'un
/// premier essai qui appliquait `.trim()` avant le test du motif acceptait
/// silencieusement une adresse précédée d'une espace (" nom@domaine.com"),
/// alors que cette espace parasite doit être rejetée : seule la vacuité
/// (chaîne uniquement composée d'espaces) doit être déléguée à `requiredField`.
Validator matchesPattern(RegExp pattern, {required String message}) {
  return (String? value) {
    final String brut = value ?? '';
    if (brut.trim().isEmpty) return null;
    if (!pattern.hasMatch(brut)) {
      return message;
    }
    return null;
  };
}

/// La valeur doit être un entier, éventuellement borné.
Validator integerValue({
  bool strictlyPositive = false,
  String message = 'Saisissez un nombre entier valide.',
  String positiveMessage = 'Saisissez un nombre entier strictement positif.',
}) {
  return (String? value) {
    final String texte = (value ?? '').trim();
    if (texte.isEmpty) return null;
    final int? n = int.tryParse(texte);
    if (n == null) return message;
    if (strictlyPositive && n <= 0) return positiveMessage;
    return null;
  };
}

/// La valeur doit être un nombre décimal (utilisé pour le tarif), positif ou
/// nul. Le séparateur décimal accepté est le point (le formatteur de saisie
/// impose ce format en amont).
Validator decimalValue({
  String message = 'Saisissez un montant valide, par exemple 12.50.',
}) {
  return (String? value) {
    final String texte = (value ?? '').trim();
    if (texte.isEmpty) return null;
    final double? n = double.tryParse(texte);
    if (n == null || n < 0) return message;
    return null;
  };
}

/// Combine plusieurs validateurs : exécute chacun dans l'ordre et retourne le
/// premier message d'erreur non nul rencontré. Retourne null si tous passent.
Validator compose(List<Validator> validators) {
  return (String? value) {
    for (final Validator validate in validators) {
      final String? erreur = validate(value);
      if (erreur != null) return erreur;
    }
    return null;
  };
}

/// Expression régulière de courriel de forme générale, commentée ligne par
/// ligne. Elle ne prétend pas couvrir la RFC 5322 dans son intégralité (aucune
/// expression réaliste ne le fait) : elle rejette les cas grossièrement
/// invalides tout en acceptant les adresses courantes.
final RegExp emailPattern = RegExp(
  r'^' // ancre de début : la correspondance doit couvrir toute la chaîne
  r"[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+" // partie locale : lettres, chiffres et
  // symboles usuellement tolérés avant l'arobase (un ou plusieurs caractères)
  r'@' // séparateur obligatoire entre partie locale et domaine
  r'[a-zA-Z0-9]' // le domaine commence par un caractère alphanumérique
  r'(?:[a-zA-Z0-9-]*[a-zA-Z0-9])?' // corps du premier label, tirets tolérés
  // au milieu mais pas en bord de label
  r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*' // labels supplémentaires
  // séparés par un point, ex. "mail.exemple"
  r'\.[a-zA-Z]{2,}' // extension finale : un point suivi d'au moins deux
  // lettres, ex. ".com", ".fr"
  r'$', // ancre de fin
);

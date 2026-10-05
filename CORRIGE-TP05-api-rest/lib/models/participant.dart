/// Modèle léger utilisé pour la liste et la recherche (`/users`,
/// `/users/search`). Écrit à la main, sans génération de code.
///
/// Le `fromJson` est défensif : aucun champ manquant, nul, mal typé ou
/// imbriqué de façon inattendue ne doit lever d'exception. Chaque valeur de
/// repli est choisie pour rester affichable sans induire l'utilisateur en
/// erreur (chaîne vide plutôt que "null", 0 plutôt qu'une exception).
class Participant {
  const Participant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.imageUrl,
    required this.companyName,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String imageUrl;
  final String companyName;

  String get fullName => '$firstName $lastName'.trim();

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: _asInt(json['id']),
      firstName: _asString(json['firstName']),
      lastName: _asString(json['lastName']),
      email: _asString(json['email']),
      imageUrl: _asString(json['image']),
      companyName: _companyName(json['company']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'image': imageUrl,
        'company': {'name': companyName},
      };

  /// Extrait `company.name` en tolérant : sous-objet absent, sous-objet
  /// `null`, sous-objet qui n'est pas une Map, ou clé `name` absente/nulle.
  static String _companyName(Object? company) {
    if (company is Map<String, dynamic>) {
      return _asString(company['name'], fallback: 'Non renseigné');
    }
    return 'Non renseigné';
  }

  /// Convertit en `int` en tolérant une valeur nulle, une valeur déjà
  /// entière, ou un nombre reçu sous forme de chaîne (`"id": "5"`).
  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Convertit en `String` en tolérant une valeur nulle ou d'un autre type
  /// (un nombre, par exemple) en la reconvertissant en texte plutôt qu'en
  /// levant une exception de type.
  static String _asString(Object? value, {String fallback = ''}) {
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }
}

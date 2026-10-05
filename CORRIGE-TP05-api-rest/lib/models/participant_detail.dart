import 'participant.dart';

/// Modèle de l'écran de détail (`GET /users/{id}`), qui expose davantage de
/// champs que la liste. Réutilise les mêmes conversions défensives que
/// [Participant] plutôt que de dupliquer la logique de secours.
class ParticipantDetail {
  const ParticipantDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.imageUrl,
    required this.companyName,
    required this.phone,
    required this.address,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String imageUrl;
  final String companyName;
  final String phone;
  final String address;

  String get fullName => '$firstName $lastName'.trim();

  factory ParticipantDetail.fromJson(Map<String, dynamic> json) {
    return ParticipantDetail(
      id: ParticipantJsonHelpers.asInt(json['id']),
      firstName: ParticipantJsonHelpers.asString(json['firstName']),
      lastName: ParticipantJsonHelpers.asString(json['lastName']),
      email: ParticipantJsonHelpers.asString(json['email']),
      imageUrl: ParticipantJsonHelpers.asString(json['image']),
      companyName: ParticipantJsonHelpers.companyName(json['company']),
      phone: ParticipantJsonHelpers.asString(
        json['phone'],
        fallback: 'Non renseigné',
      ),
      address: _formatAddress(json['address']),
    );
  }

  /// L'adresse arrive sous la forme `{address, city, state, ...}` : on la
  /// recompose en une ligne lisible, en tolérant un sous-objet absent ou
  /// mal formé, sans jamais planter sur une clé manquante.
  static String _formatAddress(Object? address) {
    if (address is Map<String, dynamic>) {
      final rue = ParticipantJsonHelpers.asString(address['address']);
      final ville = ParticipantJsonHelpers.asString(address['city']);
      final parts = [rue, ville].where((p) => p.isNotEmpty);
      if (parts.isEmpty) return 'Non renseignée';
      return parts.join(', ');
    }
    return 'Non renseignée';
  }
}

/// Fonctions de conversion défensive partagées entre [Participant] et
/// [ParticipantDetail], pour éviter de dupliquer la même logique de secours
/// dans deux modèles écrits à la main.
class ParticipantJsonHelpers {
  static String companyName(Object? company) {
    if (company is Map<String, dynamic>) {
      return asString(company['name'], fallback: 'Non renseigné');
    }
    return 'Non renseigné';
  }

  static int asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String asString(Object? value, {String fallback = ''}) {
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }
}

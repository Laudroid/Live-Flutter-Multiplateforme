import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle d'un événement de la collection Firestore `events`.
///
/// `ownerId` et `createdAt` sont exigés par l'énoncé (Partie C.1) : le
/// premier permet aux règles de sécurité de restreindre l'accès à son
/// propriétaire, le second utilise `FieldValue.serverTimestamp()` pour éviter
/// de faire confiance à l'horloge (potentiellement fausse ou décalée) de
/// l'appareil qui crée le document.
class Event {
  final String id;
  final String title;
  final String location;
  final String ownerId;
  final DateTime? createdAt;

  /// True si ce document provient du cache local du SDK et n'est pas encore
  /// confirmé par le serveur (voir `metadata.isFromCache`, Partie C.5).
  final bool isFromCache;

  const Event({
    required this.id,
    required this.title,
    required this.location,
    required this.ownerId,
    required this.createdAt,
    required this.isFromCache,
  });

  factory Event.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return Event(
      id: doc.id,
      title: (data['title'] as String?) ?? '(sans titre)',
      location: (data['location'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      isFromCache: doc.metadata.isFromCache,
    );
  }

  /// Payload à envoyer à Firestore pour créer un nouvel événement.
  ///
  /// `createdAt` utilise le serveur, pas `DateTime.now()` local : voir
  /// l'énoncé Partie C.1 et le commentaire de classe ci-dessus.
  static Map<String, dynamic> creationPayload({
    required String title,
    required String location,
    required String ownerId,
  }) {
    return {
      'title': title,
      'location': location,
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

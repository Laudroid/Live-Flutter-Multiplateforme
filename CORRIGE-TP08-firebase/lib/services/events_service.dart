import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';

/// Accès à la collection Firestore `events`, isolé dans un service dédié
/// plutôt qu'appelé directement depuis les écrans.
///
/// Ce découpage n'est pas exigé littéralement par l'énoncé mais rend visible,
/// en un seul endroit, la requête exacte utilisée pour la Partie C (filtrage
/// par `ownerId`, tri par `createdAt`) et le point où un index composite
/// devient nécessaire (voir CORRIGE.md, tableau des pièges).
class EventsService {
  EventsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  /// Flux temps réel des événements de l'organisateur [ownerId].
  ///
  /// `where('ownerId', isEqualTo: ownerId).orderBy('createdAt')` combine un
  /// filtre d'égalité et un tri sur deux champs différents : c'est
  /// précisément la combinaison qui, sur une collection réelle, réclame un
  /// index composite (Partie C.6). Sans données ni projet Firebase réel dans
  /// ce conteneur, cet index ne peut pas être provoqué ici ; voir le tableau
  /// des pièges du CORRIGE.md pour le message exact que Firestore renvoie
  /// dans ce cas et la marche à suivre.
  Stream<List<Event>> watchOwnEvents(String ownerId) {
    return _events
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Event.fromSnapshot).toList());
  }

  /// Crée un nouvel événement appartenant à [ownerId].
  ///
  /// On n'utilise jamais l'UID de l'organisateur comme identifiant du
  /// document (l'énoncé l'interdit explicitement, Partie C.1) : un même
  /// organisateur crée plusieurs événements, donc Firestore génère un
  /// identifiant de document via `add`.
  Future<void> createEvent({
    required String title,
    required String location,
    required String ownerId,
  }) {
    return _events.add(
      Event.creationPayload(title: title, location: location, ownerId: ownerId),
    );
  }

  Future<void> deleteEvent(String eventId) {
    return _events.doc(eventId).delete();
  }
}

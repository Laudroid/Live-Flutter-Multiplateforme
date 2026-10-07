import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/events_service.dart';
import '../services/navigation.dart';
import 'profile_screen.dart';

/// Espace organisateur (Partie B et Partie C).
///
/// Regroupe : bandeau de vérification de courriel (B.6), déconnexion sans
/// retour arrière (B.5), liste temps réel des événements de l'organisateur
/// connecté avec distinction cache/serveur (C.2 et C.5), et traitement du
/// refus d'accès Firestore comme cas fonctionnel (C.4).
class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  final _eventsService = EventsService();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  bool _emailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  // Abonnement souscrit manuellement (donc hors du cycle de vie automatique
  // d'un StreamBuilder) : il maintient _emailVerified à jour en tâche de
  // fond pendant toute la durée de vie de cet écran, y compris si
  // user.reload() est déclenché ailleurs. Exigence Partie C.8 : tout
  // StreamSubscription manuel doit être annulé dans dispose() — voir plus
  // bas. C'est la seule souscription manuelle de ce projet ; toute autre
  // observation d'un flux Firebase passe par StreamBuilder, qui gère son
  // propre cycle de vie et n'a donc pas besoin d'être listée ici.
  StreamSubscription<User?>? _userChangesSubscription;

  @override
  void initState() {
    super.initState();
    _userChangesSubscription =
        FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() => _emailVerified = user?.emailVerified ?? false);
      }
    });
  }

  @override
  void dispose() {
    // Justification : cette souscription a été créée manuellement dans
    // initState, elle doit donc être annulée manuellement ici pour éviter
    // un callback appelé après la destruction du widget (setState sur un
    // widget démonté).
    _userChangesSubscription?.cancel();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    // Exigence Partie B.5 : impossible de revenir à l'espace privé avec le
    // bouton retour après déconnexion. On purge la pile de navigation
    // jusqu'à la toute première route (celle d'AuthGate) via la clé
    // racine : voir le commentaire de lib/services/navigation.dart pour la
    // raison de ce choix plutôt qu'un Navigator.of(context) local.
    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    await FirebaseAuth.instance.signOut();
    // authStateChanges() émet désormais `null` : AuthGate, qui est la
    // première route ci-dessus, reconstruit son StreamBuilder et affiche
    // LoginScreen.
  }

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _eventsService.createEvent(
      title: title,
      location: _locationController.text.trim(),
      ownerId: uid,
    );
    _titleController.clear();
    _locationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour, ${user?.displayName ?? user?.email ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_emailVerified) _EmailVerificationBanner(user: user),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de l\'événement',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lieu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _createEvent,
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: uid == null
                ? const Center(child: Text('Session invalide.'))
                : StreamBuilder<List<Event>>(
                    stream: _eventsService.watchOwnEvents(uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        // Exigence Partie C.4 : un refus d'accès Firestore
                        // (FirebaseException code permission-denied) est un
                        // cas fonctionnel normal, traité ici par un message
                        // stable, pas par un écran qui plante.
                        final error = snapshot.error;
                        final isPermissionDenied = error is FirebaseException &&
                            error.code == 'permission-denied';
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              isPermissionDenied
                                  ? 'Accès refusé : les règles de sécurité '
                                      'Firestore interdisent cette lecture. '
                                      'Vérifiez que vous êtes bien connecté '
                                      'et propriétaire de ces événements.'
                                  : 'Une erreur est survenue lors du '
                                      'chargement des événements.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final events = snapshot.data!;
                      if (events.isEmpty) {
                        return const Center(
                          child: Text('Aucun événement pour le moment.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: events.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return ListTile(
                            title: Text(event.title),
                            subtitle: Text(event.location),
                            // Exigence Partie C.5 : distinction visuelle
                            // entre écriture locale non confirmée (cache) et
                            // donnée confirmée par le serveur.
                            trailing: event.isFromCache
                                ? Tooltip(
                                    message: 'En attente de confirmation serveur',
                                    child: Icon(Icons.cloud_upload_outlined,
                                        color: Colors.orange.shade700),
                                  )
                                : Tooltip(
                                    message: 'Confirmé par le serveur',
                                    child: Icon(Icons.cloud_done_outlined,
                                        color: Colors.green.shade700),
                                  ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau non bloquant informant l'utilisateur que son adresse n'est pas
/// encore vérifiée (Partie B.6 : "sans nécessairement bloquer l'accès").
class _EmailVerificationBanner extends StatelessWidget {
  const _EmailVerificationBanner({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Votre adresse courriel n\'est pas encore vérifiée.'),
          ),
          TextButton(
            onPressed: () => user?.sendEmailVerification(),
            child: const Text('Renvoyer'),
          ),
        ],
      ),
    );
  }
}

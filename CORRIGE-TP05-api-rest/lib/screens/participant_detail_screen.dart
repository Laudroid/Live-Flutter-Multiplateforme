import 'package:flutter/material.dart';

import '../api/exceptions.dart';
import '../api/users_api.dart';
import '../models/participant_detail.dart';

/// Écran de détail alimenté par `GET /users/{id}`. Reçoit l'[UsersApi] déjà
/// construit par [DirectoryScreen] plutôt que d'en créer un second : il n'y
/// a qu'un seul `http.Client` à fermer pour tout l'écran d'annuaire.
class ParticipantDetailScreen extends StatefulWidget {
  const ParticipantDetailScreen({
    super.key,
    required this.userId,
    required this.api,
  });

  final int userId;
  final UsersApi api;

  @override
  State<ParticipantDetailScreen> createState() =>
      _ParticipantDetailScreenState();
}

class _ParticipantDetailScreenState extends State<ParticipantDetailScreen> {
  // Le Future est mémorisé dans initState, pour la même raison que dans
  // DirectoryScreen : un FutureBuilder dont le `future` est reconstruit à
  // chaque build relancerait la requête à chaque recomposition de cet écran
  // (par exemple lors de l'ouverture du clavier ou d'une rotation).
  late Future<ParticipantDetail> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = widget.api.fetchUserDetail(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche participant')),
      body: FutureBuilder<ParticipantDetail>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _messageUtilisateur(snapshot.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Aucune donnée disponible.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(detail.imageUrl),
                  onBackgroundImageError: (_, _) {},
                ),
              ),
              const SizedBox(height: 16),
              Text(
                detail.fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _Champ(label: 'Entreprise', valeur: detail.companyName),
              _Champ(label: 'Courriel', valeur: detail.email),
              // Champ supplémentaire non présent dans la liste, exigé par
              // la consigne de la partie B.5.
              _Champ(label: 'Téléphone', valeur: detail.phone),
              _Champ(label: 'Adresse', valeur: detail.address),
            ],
          );
        },
      ),
    );
  }

  /// Ne jamais afficher `error.toString()` brut si l'erreur n'est pas déjà
  /// une [ApiException] : un widget cassé (par exemple `NetworkImage`) peut
  /// remonter une exception qui n'a pas de message pensé pour l'affichage.
  String _messageUtilisateur(Object? erreur) {
    if (erreur is ApiException) return erreur.message;
    return 'Une erreur inattendue est survenue, veuillez réessayer.';
  }
}

class _Champ extends StatelessWidget {
  const _Champ({required this.label, required this.valeur});

  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(valeur)),
        ],
      ),
    );
  }
}

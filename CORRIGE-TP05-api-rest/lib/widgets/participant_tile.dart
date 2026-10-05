import 'package:flutter/material.dart';

import '../models/participant.dart';

/// Une ligne de la liste. Extrait dans son propre fichier pour que
/// [DirectoryScreen] reste concentré sur la logique d'état (pagination,
/// requêtes) plutôt que sur la mise en forme visuelle d'une ligne.
class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.participant,
    required this.onTap,
  });

  final Participant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(participant.imageUrl),
        onBackgroundImageError: (_, _) {},
      ),
      title: Text(participant.fullName),
      subtitle: Text(participant.companyName),
      onTap: onTap,
    );
  }
}

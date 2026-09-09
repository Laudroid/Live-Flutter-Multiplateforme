import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/event_repository.dart';
import '../models/session.dart';
import '../state/registration_cart.dart';
import '../widgets/cart_badge.dart';

/// Écran de détail d'un événement : choix d'une session et d'une quantité,
/// puis ajout au panier. Reçoit uniquement `eventId` en paramètre de
/// navigation (réemploi du TP 3) : les données de l'événement sont
/// relues depuis `EventRepository`, pas transmises en dur d'un écran à
/// l'autre.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Session? _sessionChoisie;

  /// Quantité en cours de saisie : état strictement local à ce formulaire
  /// d'ajout, sans intérêt pour aucun autre écran tant que l'ajout n'a pas
  /// été confirmé. `TextField`/`TextFormField` sont hors périmètre du TP4 :
  /// un compteur +/- suffit et reste dans le périmètre autorisé.
  int _quantite = 1;

  @override
  Widget build(BuildContext context) {
    // context.read suffit ici : le dépôt en dur ne change jamais pendant
    // la vie de l'écran, aucune raison de s'abonner à quoi que ce soit.
    final repository = context.read<EventRepository>();
    final event = repository.parId(widget.eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Événement introuvable')),
        body: const Center(child: Text('Cet événement n\'existe plus.')),
      );
    }

    _sessionChoisie ??= event.sessions.first;
    final placesRestantes = event.capacite - event.placesPrises;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.titre),
        actions: const [CartBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${event.categorie} · $placesRestantes place(s) restante(s) '
            'sur ${event.capacite}',
          ),
          const SizedBox(height: 16),
          Text('Session', style: Theme.of(context).textTheme.titleMedium),
          // RadioGroup<Session> remplace le couple groupValue/onChanged de
          // RadioListTile, déprécié depuis Flutter 3.32 : le groupe gère
          // désormais la sélection pour tous ses `Radio`/`RadioListTile`
          // descendants.
          RadioGroup<Session>(
            groupValue: _sessionChoisie,
            onChanged: (valeur) => setState(() => _sessionChoisie = valeur),
            child: Column(
              children: [
                for (final session in event.sessions)
                  RadioListTile<Session>(
                    title: Text('${session.libelle} (${session.horaire})'),
                    value: session,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Quantité', style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantite > 1
                    ? () => setState(() => _quantite--)
                    : null,
              ),
              Text('$_quantite', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantite++),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // context.read : mutation ponctuelle sur pression du bouton.
              final resultat = context.read<RegistrationCart>().ajouter(
                    event: event,
                    session: _sessionChoisie!,
                    quantite: _quantite,
                  );
              final message = switch (resultat) {
                ResultatAjout.succes => 'Ajouté au panier.',
                ResultatAjout.dejaDansLePanier =>
                  'Cet événement est déjà dans le panier. Modifiez la '
                      'quantité depuis l\'écran panier.',
                ResultatAjout.evenementComplet =>
                  'Refusé : il ne reste pas assez de places sur cet '
                      'événement.',
                ResultatAjout.plafondDepasse =>
                  'Refusé : le plafond de ${RegistrationCart.plafondPlaces} '
                      'places par utilisateur serait dépassé.',
              };
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            child: const Text('Ajouter au panier'),
          ),
        ],
      ),
    );
  }
}

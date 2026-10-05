import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_draft.dart';

/// Récapitulatif en lecture seule avant confirmation définitive.
///
/// Reçoit une instance déjà construite d'`EventDraft` : cet écran n'a plus
/// aucun accès aux contrôleurs de saisie, ce qui démontre concrètement que le
/// modèle est exploitable indépendamment du formulaire qui l'a produit.
/// Aucun widget de saisie ici : uniquement des `Text` en lecture seule.
class EventSummaryScreen extends StatelessWidget {
  const EventSummaryScreen({super.key, required this.draft});

  final EventDraft draft;

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatMonetaire = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    Widget ligne(String libelle, String valeur) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(libelle, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(valeur)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Récapitulatif')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  ligne('Titre', draft.title),
                  ligne('Description', draft.description),
                  ligne('Catégorie', draft.category),
                  ligne('Capacité', '${draft.capacity} places'),
                  ligne('En ligne', draft.isOnline ? 'Oui' : 'Non'),
                  ligne('Adresse', draft.address ?? '(non applicable, événement en ligne)'),
                  ligne('Date de début', _formatDate(draft.startDate)),
                  ligne('Date de fin', _formatDate(draft.endDate)),
                  ligne('Heure de début', draft.startTime.format(context)),
                  ligne('Gratuit', draft.isFree ? 'Oui' : 'Non'),
                  ligne('Tarif', draft.isFree ? 'Gratuit' : formatMonetaire.format(draft.price)),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Corriger'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // On lit exclusivement l'instance `draft`, jamais un
                      // contrôleur : preuve que le modèle est autonome.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Événement « ${draft.title} » créé pour le '
                            '${_formatDate(draft.startDate)}.',
                          ),
                        ),
                      );
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

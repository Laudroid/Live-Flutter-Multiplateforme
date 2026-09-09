import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/formule.dart';

/// Écran de sélection de formule (Partie B).
///
/// Ne pousse aucun nouvel écran : il renvoie sa sélection à l'appelant via
/// `Navigator.pop(context, formule)`. Il intercepte aussi toute tentative de
/// retour (Partie C, point 4) pour demander confirmation d'abandon.
class PackageSelectionScreen extends StatefulWidget {
  const PackageSelectionScreen({super.key, required this.event});

  final Event event;

  @override
  State<PackageSelectionScreen> createState() =>
      _PackageSelectionScreenState();
}

class _PackageSelectionScreenState extends State<PackageSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope<Formule?>(
      // canPop=false : toute tentative de retour matérielle ou applicative
      // (bouton retour Android, flèche de l'AppBar — les deux passent par
      // Navigator.maybePop) est interceptée par onPopInvokedWithResult
      // ci-dessous plutôt qu'exécutée directement.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Formule? result) {
        if (didPop) {
          // La pop a déjà eu lieu (cas canPop=true, non utilisé ici, ou pop
          // direct réussi) : rien à faire.
          return;
        }
        // La tentative a été bloquée : on ne sait pas si c'est un retour
        // matériel (résultat toujours null dans ce cas précis, puisque ni le
        // bouton retour ni la flèche AppBar ne transportent de valeur) ou un
        // pop applicatif direct. Ici, un pop direct via `_choisir` n'est
        // JAMAIS intercepté (voir commentaire de `_choisir`) : ce callback
        // ne se déclenche donc que pour un véritable abandon.
        _confirmerAbandon();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Formule — ${widget.event.title}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Choisissez une formule de participation :',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final Formule formule in formulesDisponibles)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(formule.label),
                  subtitle: Text(formule.description),
                  trailing: Text(
                    '${formule.tarifEuros.toStringAsFixed(0)} €',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => _choisir(formule),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Sélection délibérée : appel DIRECT à `Navigator.pop`, jamais à
  /// `Navigator.maybePop`. D'après la documentation de `PopScope` et
  /// l'exemple officiel `pop_scope.1.dart` du SDK, `canPop` ne gouverne que
  /// les tentatives passant par `Navigator.maybePop` (bouton retour
  /// matériel, flèche de l'AppBar) ; un `Navigator.pop` direct aboutit
  /// toujours, qu'importe la valeur de `canPop`. Choisir une formule ne
  /// déclenche donc jamais le dialogue de confirmation — ce qui est le
  /// comportement voulu, l'utilisateur venant de faire un choix délibéré.
  void _choisir(Formule formule) {
    Navigator.pop(context, formule);
  }

  Future<void> _confirmerAbandon() async {
    final bool? quitter = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Abandonner la sélection en cours ?'),
          content: const Text(
            'Vous reviendrez à l\'écran de détail sans avoir choisi de '
            'formule.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Rester ici'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Abandonner'),
            ),
          ],
        );
      },
    );
    if (quitter == true && mounted) {
      // Pop direct, sans valeur : `formule` reçue par l'appelant sera bien
      // `null`, traité comme une annulation par EventDetailScreen.
      Navigator.pop(context);
    }
  }
}

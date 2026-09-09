import 'package:flutter/material.dart';

/// Jauge de places restantes, réutilisée par la carte d'événement et par
/// l'écran de détail (widget partagé, comme l'exige l'énoncé).
class JaugePlaces extends StatelessWidget {
  const JaugePlaces({super.key, required this.taux, required this.libelle});

  final double taux;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final Color couleur = taux >= 1
        ? Colors.red
        : taux >= 0.8
        ? Colors.orange
        : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: taux.clamp(0, 1),
            minHeight: 6,
            backgroundColor: couleur.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(couleur),
          ),
        ),
        const SizedBox(height: 4),
        Text(libelle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Indicateur statistique : une valeur mise en avant et un libellé sous
/// elle, centrés, destiné à occuper une des trois zones égales de la barre
/// de statistiques.
///
/// Ne reçoit que des `String` : il ignore d'où vient la valeur (un compte
/// d'événements, de catégories ou d'inscrits). `FittedBox` garantit que la
/// valeur ne déborde jamais de sa zone même si elle passe à cinq chiffres,
/// sans jamais faire appel à `MediaQuery`.
class StatIndicator extends StatelessWidget {
  const StatIndicator({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

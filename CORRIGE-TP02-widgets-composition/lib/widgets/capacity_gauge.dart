import 'package:flutter/material.dart';

/// Jauge de remplissage : une piste grise pleine largeur et une barre
/// colorée dont la largeur est une fraction de la piste.
///
/// Reçoit deux entiers primitifs (`registered`, `capacity`) plutôt qu'un
/// `Event` : c'est ce widget, et lui seul, qui porte la responsabilité de
/// borner le taux à 1.0. Centraliser le calcul ici évite qu'un appelant
/// oublie de le faire et laisse passer une barre plus large que sa piste
/// lorsque `registered > capacity` (cas de sur-réservation imposé par le
/// jeu de données).
///
/// La largeur de la barre est exprimée avec `FractionallySizedBox`
/// (fraction de l'espace donné par le parent) plutôt qu'avec un calcul en
/// pixels : cela évite tout recours à `LayoutBuilder`, hors périmètre du
/// TP, tout en restant correct quelle que soit la largeur de la carte.
class CapacityGauge extends StatelessWidget {
  const CapacityGauge({
    super.key,
    required this.registered,
    required this.capacity,
    this.height = 6,
  });

  final int registered;
  final int capacity;
  final double height;

  double get _ratio {
    if (capacity <= 0) return 0;
    final raw = registered / capacity;
    return raw.clamp(0.0, 1.0);
  }

  Color _colorForRatio(ColorScheme scheme) {
    final ratio = _ratio;
    if (ratio >= 1.0) return scheme.error;
    if (ratio >= 0.75) return Colors.orange;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        children: [
          Container(height: height, color: scheme.surfaceContainerHighest),
          FractionallySizedBox(
            // `widthFactor` est déjà borné à [0, 1] par `_ratio` : c'est ce
            // clamp qui garantit que la barre ne dépasse jamais sa piste.
            widthFactor: _ratio,
            child: Container(height: height, color: _colorForRatio(scheme)),
          ),
        ],
      ),
    );
  }
}

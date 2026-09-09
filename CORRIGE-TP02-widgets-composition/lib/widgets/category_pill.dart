import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Pastille arrondie purement décorative (aucun comportement au tap, comme
/// demandé par l'énoncé pour les filtres de la partie B).
///
/// Reçoit uniquement une [String] et un état [selected] booléen : elle
/// ignore totalement l'existence d'un `Event` ou d'une catégorie métier.
class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: Spacing.hairline,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

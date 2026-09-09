import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Ligne « icône + libellé » réutilisable.
///
/// Ne connaît rien du modèle `Event` : elle reçoit une [IconData] et une
/// [String], ce qui lui permet de servir aussi bien pour le lieu que pour
/// la date, ou pour tout autre couple icône/texte futur. Le texte est
/// tronqué avec ellipse pour ne jamais faire déborder la ligne quand le
/// libellé est long (nom de lieu long du jeu de données, par exemple).
class IconLabel extends StatelessWidget {
  const IconLabel({
    super.key,
    required this.icon,
    required this.label,
    this.iconSize = 14,
    this.style,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final double iconSize;
  final TextStyle? style;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: Spacing.xs),
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/spacing.dart';
import '../utils/date_label.dart';
import 'capacity_gauge.dart';
import 'icon_label.dart';

/// Deux densités d'affichage pour `EventCard` (partie C, exigence 2).
///
/// `comfortable` est la densité par défaut de la partie A ; `compact`
/// réduit la vignette, retire la jauge et limite le titre à une ligne.
enum EventCardDensity { comfortable, compact }

/// Carte présentant un [Event] : vignette carrée à gauche, bloc textuel à
/// droite (titre, lieu, date, jauge).
///
/// L'ordre de l'arborescence suit strictement celui imposé par l'énoncé :
/// `Container` externe (décoration) > `Row` > vignette contrainte à gauche,
/// bloc textuel `Column` à droite avec, dans l'ordre, le titre, la ligne
/// lieu, la ligne date, puis la jauge.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.density = EventCardDensity.comfortable,
  });

  final Event event;
  final EventCardDensity density;

  bool get _isCompact => density == EventCardDensity.compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnailSize = _isCompact ? 56.0 : 88.0;
    final titleMaxLines = _isCompact ? 1 : 2;
    final verticalGap = _isCompact ? Spacing.xs : Spacing.sm;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant,
          width: Spacing.hairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(
            imageUrl: event.imageUrl,
            size: thumbnailSize,
            isSoldOut: event.isSoldOut,
          ),
          const SizedBox(width: Spacing.md),
          // `Expanded` force le bloc textuel à occuper tout l'espace
          // horizontal restant, quelle que soit la largeur de la carte :
          // c'est ce qui empêche un titre long de pousser la vignette hors
          // cadre et de provoquer un `RenderFlex overflowed`.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: verticalGap),
                IconLabel(
                  icon: event.isOnline
                      ? Icons.wifi_outlined
                      : Icons.place_outlined,
                  label: event.isOnline
                      ? event.venue
                      : '${event.venue}, ${event.city}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                  iconColor: scheme.onSurfaceVariant,
                ),
                SizedBox(height: Spacing.xs),
                IconLabel(
                  icon: Icons.schedule_outlined,
                  label: formatEventDate(event.date),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                  iconColor: scheme.onSurfaceVariant,
                ),
                if (!_isCompact) ...[
                  const SizedBox(height: Spacing.sm),
                  CapacityGauge(
                    registered: event.registered,
                    capacity: event.capacity,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vignette carrée contrainte par `SizedBox` + `AspectRatio`, avec un
/// `errorBuilder` pour rester correcte sans accès réseau, et un badge
/// « Complet » superposé (via `Stack`) lorsque l'événement est complet.
///
/// Le badge est posé sur la vignette plutôt qu'inséré dans la `Column`
/// textuelle : cela préserve l'ordre imposé par l'énoncé pour le bloc de
/// droite (titre, lieu, date, jauge) sans ajouter de nœud supplémentaire.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.imageUrl,
    required this.size,
    required this.isSoldOut,
  });

  final String imageUrl;
  final double size;
  final bool isSoldOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacing.radiusSm),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: scheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: size * 0.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          if (isSoldOut)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(Spacing.radiusSm),
                    bottomRight: Radius.circular(Spacing.radiusSm),
                  ),
                ),
                child: Text(
                  'Complet',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: scheme.onError,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

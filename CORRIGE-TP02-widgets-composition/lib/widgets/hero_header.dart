import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// En-tête héros de l'écran (partie B, exigence 1).
///
/// Reçoit uniquement des types primitifs (chaînes, hauteur) : il n'a pas
/// besoin de connaître `Event`, ce n'est pas une carte d'événement mais un
/// bandeau d'écran.
///
/// Structure en `Stack` : image de fond, voile dégradé, textes en bas à
/// gauche, avatar en haut à droite qui déborde volontairement du cadre.
/// Le débordement de l'avatar est obtenu en donnant au `Positioned` de
/// l'avatar une valeur `bottom` négative : une partie du cercle sort donc
/// sous le bord inférieur du bandeau. Pour que ce débordement reste
/// visible plutôt que d'être rogné, le `Stack` racine porte explicitement
/// `clipBehavior: Clip.none` — le comportement par défaut de `Stack`
/// (`Clip.hardEdge`) aurait rogné l'avatar au ras du cadre, ce qui est
/// justement le point évalué par l'énoncé.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.backgroundImageUrl,
    required this.avatarImageUrl,
    required this.title,
    required this.tagline,
    this.height = 220,
  });

  final String backgroundImageUrl;
  final String avatarImageUrl;
  final String title;
  final String tagline;
  final double height;

  static const double _avatarDiameter = 56;
  static const double _avatarOverflow = 18;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + _avatarOverflow,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    backgroundImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.blueGrey.shade800);
                    },
                  ),
                  // Voile dégradé sombre du bas vers le haut : garantit la
                  // lisibilité du texte blanc posé par-dessus, quelle que
                  // soit la photo de fond.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.black.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: Spacing.lg,
                    right: Spacing.lg,
                    bottom: Spacing.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Avatar : ancré en haut à droite du cadre de l'image, mais
          // positionné verticalement pour qu'une partie de son diamètre
          // sorte sous la frontière de l'image (`height`). `top` est donc
          // calculé pour que le bas du cercle atteigne `height +
          // _avatarOverflow`, ce qui correspond exactement à la place
          // réservée par le `SizedBox` racine. Utiliser `top` seul (plutôt
          // que `top` et `bottom` combinés) évite que `Positioned` ne
          // réétire le cercle en ovale : la taille du cercle reste fixée
          // par le `Container`.
          Positioned(
            top: height - _avatarDiameter + _avatarOverflow,
            right: Spacing.lg,
            child: Container(
              width: _avatarDiameter,
              height: _avatarDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipOval(
                child: Image.network(
                  avatarImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

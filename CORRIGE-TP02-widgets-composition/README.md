# corrige_tp02_widgets — Event Planner (mur d'événements)

## Mise en route

```bash
flutter pub get
flutter analyze
flutter run
```

## Découplage des widgets extraits (partie C, exigence 1)

`IconLabel`, `CategoryPill`, `CapacityGauge` et `StatIndicator` ne reçoivent que des types
primitifs (`String`, `int`, `bool`, `IconData`) et jamais un `Event`. Ce choix les rend
utilisables ailleurs dans l'application sans dépendre du modèle métier, et surtout testables
unitairement sans construire un `Event` complet. Le prix de ce découplage est que l'appelant
(`EventCard`, `EventWallScreen`) doit lui-même extraire les champs pertinents de l'`Event`
avant de les transmettre — un couplage explicite et local, préférable au couplage implicite
qu'aurait introduit un widget acceptant l'objet métier entier.

## Arbre de widgets annoté

```
MaterialApp
└── EventWallScreen (StatefulWidget — seul point d'état : bool _isCompact)
    └── Scaffold
        ├── AppBar                        // titre + interrupteur de densité
        │   └── Switch                    // unique setState de l'application
        └── SingleChildScrollView         // l'écran entier défile d'un bloc
            └── Column                    // empilement vertical des sections
                ├── HeroHeader
                │   └── SizedBox           // réserve la place du débordement de l'avatar
                │       └── Stack(clipBehavior: Clip.none)  // débordement non rogné
                │           ├── Positioned → ClipRect → Stack(fit: expand)
                │           │   ├── Image.network           // photo de fond, errorBuilder
                │           │   ├── DecoratedBox(gradient)   // voile de lisibilité
                │           │   └── Positioned → Column      // titre + accroche, bas gauche
                │           └── Positioned → Container(circle) → ClipOval → Image.network
                │                                            // avatar, déborde sous le cadre
                ├── _StatsBar
                │   └── IntrinsicHeight                      // force les séparateurs pleine hauteur
                │       └── Row
                │           ├── Expanded → StatIndicator     // "8" / "événements"
                │           ├── VerticalDivider               // séparateur 1px pleine hauteur
                │           ├── Expanded → StatIndicator     // "3" / "catégories"
                │           ├── VerticalDivider
                │           └── Expanded → StatIndicator     // "412" / "inscrits"
                ├── _FiltersRow
                │   └── Wrap                                  // passe à la ligne sans débordement
                │       └── CategoryPill × n
                ├── _SectionHeader
                │   └── Row(mainAxisAlignment: spaceBetween)  // titre et compteur aux extrêmes
                ├── EventCard × n (comfortable ou compact selon _isCompact)
                │   └── Container (décoration : rayon 16, bordure fine, fond de surface)
                │       └── Row
                │           ├── _Thumbnail
                │           │   └── Stack(clipBehavior: none)
                │           │       ├── ClipRRect → AspectRatio → Image.network
                │           │       └── Positioned → badge "Complet" (si isSoldOut)
                │           └── Expanded → Column             // occupe tout l'espace restant
                │               ├── Text (titre, 1 ou 2 lignes selon densité)
                │               ├── IconLabel                 // lieu (ou "en ligne")
                │               ├── IconLabel                 // date formatée à la main
                │               └── CapacityGauge              // absente en densité compacte
                │                   └── ClipRRect → Stack
                │                       ├── Container          // piste grise pleine largeur
                │                       └── FractionallySizedBox → Container  // remplissage, borné à 1.0
                └── _Footer
                    └── Center → Text                          // mention légale
```

## Tableau des cas limites

| Cas limite | Widget qui absorbe la contrainte | Comportement obtenu |
| --- | --- | --- |
| Titre de plus de 70 caractères (index 0 de `sampleEvents`) | `Text` du titre dans `EventCard`, contraint par l'`Expanded` parent + `maxLines`/`overflow: ellipsis` | Le titre s'arrête à 2 lignes (1 en densité compacte) avec points de suspension ; la vignette garde sa taille fixe, aucun `RenderFlex overflowed`. |
| Libellé statistique remplacé par une valeur à cinq chiffres | `FittedBox` dans `StatIndicator` | Le chiffre se réduit pour tenir dans la largeur de sa zone (`Expanded` d'un tiers de la barre) au lieu de déborder ou de forcer un retour à la ligne. |
| Nom de lieu long (index 4, « Espace de coworking La Cordée — bâtiment B, troisième étage, salle Ariane ») | `Flexible` + `maxLines: 1`/`ellipsis` dans `IconLabel` | La ligne « icône + lieu » se tronque proprement avec une ellipse, sans repousser l'icône ni élargir la carte. |
| Sur-réservation (`registered > capacity`, index 3) | Le `clamp(0.0, 1.0)` interne à `CapacityGauge` | Le `widthFactor` de la barre de remplissage est plafonné à 1.0 : la barre colorée occupe exactement la largeur de la piste, jamais plus, et prend la couleur d'alerte (`error`). |

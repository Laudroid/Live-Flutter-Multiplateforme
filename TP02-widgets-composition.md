# TP 2 — Widgets et composition : le mur d'événements

| | |
| --- | --- |
| **Séance de référence** | Séance 2 — Widgets et composition |
| **Modalité** | Individuel |
| **Prérequis** | Séance 1 : projet Flutter fonctionnel, `flutter doctor` sans erreur bloquante, distinction `StatelessWidget` / `StatefulWidget` |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (ou version locale ; vérifier avec `flutter --version`), VSCode |

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- composer une interface non triviale à partir des seuls widgets de disposition `Row`, `Column`, `Stack` et `Container` ;
- raisonner sur l'arborescence des widgets et justifier la position de chaque nœud ;
- maîtriser la répartition de l'espace disponible (`Expanded`, `Flexible`, `SizedBox`, `Padding`, `Spacer`) et diagnostiquer un débordement ;
- appliquer correctement `MainAxisAlignment`, `CrossAxisAlignment` et `MainAxisSize` ;
- extraire des widgets réutilisables et paramétrés plutôt que de dupliquer des sous-arbres.

## Périmètre du TP

**Autorisé et attendu**

- `Row`, `Column`, `Stack`, `Positioned`, `Align`, `Center`, `Container`, `DecoratedBox`
- `Padding`, `SizedBox`, `Expanded`, `Flexible`, `Spacer`, `Wrap`, `AspectRatio`, `FittedBox`, `ConstrainedBox`
- `Text`, `Icon`, `Image.asset`, `Image.network`, `Divider`, `CircleAvatar`
- `Scaffold`, `AppBar`, `SingleChildScrollView`, `ListView` (usage statique uniquement)
- `StatelessWidget`, et `StatefulWidget` avec `setState` limité à un basculement d'affichage local (Partie C)

**Hors périmètre — l'usage sera pénalisé**

- Toute navigation : `Navigator`, `MaterialPageRoute`, routes nommées (séance 3)
- Toute gestion d'état partagé : `provider`, `ChangeNotifier`, `InheritedWidget` (séance 4)
- Tout appel réseau, `http`, `FutureBuilder`, `async` (séance 5)
- Tout formulaire : `Form`, `TextFormField`, `TextEditingController` (séance 6)
- Toute persistance (séance 7), tout Firebase (séance 8)
- `MediaQuery`, `LayoutBuilder`, widgets animés `AnimatedXxx`, `Hero` (séance 9)
- Toute dépendance externe ajoutée au `pubspec.yaml` : ce TP se fait avec le SDK seul

Les données sont **codées en dur** dans une liste Dart. C'est volontaire : la contrainte de ce TP porte exclusivement sur la composition visuelle.

## Mise en situation

Le fil rouge de la formation est une application de gestion d'événements, *Event Planner*. Avant toute logique métier, l'équipe produit veut valider la maquette de l'écran d'accueil : un « mur d'événements » présentant les prochaines rencontres d'un cycle de conférences, avec pour chaque événement une vignette, un titre, un lieu, une date, une jauge de places restantes et un badge d'état. La maquette n'est pas négociable sur un point : elle doit tenir sans débordement sur un téléphone comme sur une tablette en mode portrait, uniquement grâce à une répartition correcte des contraintes — sans interroger la taille de l'écran, notion réservée à la séance 9.

Vous produisez cet écran, et rien d'autre : aucun bouton de ce TP n'a besoin de mener quelque part.

## Jeu de données imposé

Créez `lib/data/sample_events.dart` avec au minimum huit entrées construites sur ce modèle immuable :

```dart
class Event {
  const Event({
    required this.title,
    required this.city,
    required this.venue,
    required this.date,
    required this.category,
    required this.capacity,
    required this.registered,
    required this.imageUrl,
    this.isSoldOut = false,
    this.isOnline = false,
  });

  final String title;      // peut être long : « Conférence annuelle sur l'ingénierie des systèmes distribués »
  final String city;
  final String venue;
  final DateTime date;
  final String category;   // « Conférence », « Atelier », « Meetup », « Table ronde »
  final int capacity;
  final int registered;    // peut dépasser capacity : liste d'attente
  final String imageUrl;
  final bool isSoldOut;
  final bool isOnline;
}
```

Le jeu de données doit contenir au moins : un titre très long (plus de 70 caractères), un événement complet (`isSoldOut`), un événement en ligne sans ville renseignée de façon utile, un événement dont `registered` dépasse `capacity`, et un nom de lieu long. Ces cas ne sont pas décoratifs : ils constituent le protocole de test de votre mise en page.

---

## Partie A — Prise en main guidée : la carte d'événement

Objectif : produire un widget `EventCard` isolé, correct et robuste.

1. Créez un nouveau projet (`flutter create event_planner_ui`) et videz le contenu de `main.dart` pour ne conserver qu'un `MaterialApp` et un `Scaffold` avec `AppBar`.
2. Créez `lib/widgets/event_card.dart` contenant un `StatelessWidget` de signature :
   ```dart
   class EventCard extends StatelessWidget {
     const EventCard({super.key, required this.event});
     final Event event;
     // ...
   }
   ```
3. Structurez la carte comme suit, en respectant l'ordre imposé de l'arborescence :
   - un `Container` externe portant une décoration (rayon de bordure 16, bordure fine, fond de surface) et une marge externe ;
   - à l'intérieur, une `Row` : à gauche une vignette carrée de 88 pixels de côté (`Image.network` contraint par `SizedBox` et `AspectRatio`, `fit: BoxFit.cover`), à droite le bloc textuel ;
   - le bloc textuel est une `Column` alignée sur `CrossAxisAlignment.start`, contenant successivement : le titre, une ligne « icône + lieu », une ligne « icône + date formatée à la main », et la jauge de places ;
   - le titre est limité à deux lignes, avec césure par points de suspension.
4. Faites en sorte que le bloc textuel occupe tout l'espace horizontal restant, quelle que soit la largeur de la carte. Testez avec le titre le plus long de votre jeu de données : aucun message `RenderFlex overflowed` ne doit apparaître, ni en console, ni à l'écran.
5. La jauge de places est un `Stack` de deux `Container` : une piste grise pleine largeur et une barre de remplissage colorée dont la largeur est une fraction de la piste. Le taux de remplissage est `registered / capacity`, **borné à 1.0**. Aucune arithmétique ne doit produire une barre plus large que sa piste, même lorsque `registered > capacity`.
6. Formatez la date sans dépendance externe (le package `intl` est hors périmètre pour cette partie) : une fonction utilitaire pure prenant un `DateTime` et retournant par exemple `« ven. 12 juin, 18h30 »`. Placez-la dans `lib/utils/date_label.dart`.
7. Affichez trois `EventCard` empilées dans une `Column` pour valider le rendu.

**Critères de réussite observables** : aucun débordement quel que soit l'événement affiché ; la vignette reste carrée ; le titre ne pousse jamais la vignette hors de la carte ; la jauge est correcte pour un événement à 0 inscrit, à guichet fermé et en sur-réservation.

---

## Partie B — Mise en œuvre autonome : l'écran complet

Objectif : assembler l'écran d'accueil complet.

L'écran, défilable dans son ensemble, comporte de haut en bas :

1. **Un en-tête hero**, hauteur fixe d'environ 220 pixels, construit avec `Stack` :
   - une image de fond couvrant toute la surface ;
   - un voile dégradé sombre du bas vers le haut, garantissant la lisibilité du texte ;
   - en bas à gauche, superposés, le nom du cycle de conférences et une accroche sur une ligne ;
   - en haut à droite, une pastille circulaire d'avatar débordant partiellement de l'en-tête (une partie de la pastille doit sortir du cadre de l'image, vers le bas) ;
   - le débordement doit être visible, non rogné : c'est le comportement de `Stack` et de `clipBehavior` qui est évalué ici.
2. **Une barre de statistiques** sur une seule ligne, répartissant trois indicateurs (« 8 événements », « 3 catégories », « 412 inscrits ») en trois zones de largeur strictement égale, séparées par des séparateurs verticaux de 1 pixel occupant toute la hauteur de la barre. Les libellés ne doivent jamais déborder, y compris si l'on remplace un nombre par une valeur à cinq chiffres.
3. **Une rangée de filtres par catégorie**, en pastilles arrondies, qui passe automatiquement à la ligne lorsque l'espace horizontal manque. Ces pastilles sont purement décoratives à ce stade : aucun comportement au tap n'est demandé.
4. **La liste des événements**, réutilisant `EventCard`, précédée d'un titre de section « Prochains événements » aligné à gauche et d'un compteur aligné à droite, sur la même ligne, les deux extrêmes plaqués contre les bords.
5. **Un pied d'écran** contenant une mention légale centrée, à distance constante du dernier élément.

Contraintes de composition :

- l'ensemble doit défiler d'un seul mouvement : il est interdit d'imbriquer une liste défilante dans une autre zone défilante ;
- aucune hauteur totale d'écran ne doit être codée en dur ;
- si vous employez `Expanded` à l'intérieur d'une zone défilante et que l'application lève une exception de contraintes, c'est un résultat attendu du raisonnement : corrigez la structure, ne masquez pas le symptôme.

---

## Partie C — Approfondissement : discipline d'arborescence

Cette partie évalue votre capacité d'ingénieur à produire une hiérarchie de widgets défendable.

1. **Factorisation.** Aucun sous-arbre de plus de trois nœuds ne doit apparaître deux fois dans votre code. Extrayez au minimum quatre widgets réutilisables et paramétrés, chacun dans son fichier sous `lib/widgets/` : la ligne « icône + libellé », la pastille de catégorie, la jauge, l'indicateur statistique. Chacun expose des paramètres nommés, dispose d'un constructeur `const` et ne connaît rien du modèle `Event` — ils reçoivent des types primitifs, pas l'événement entier. Justifiez ce choix de découplage en trois lignes dans le `README.md`.

2. **Deux densités d'affichage.** `EventCard` accepte un paramètre `EventCardDensity { comfortable, compact }`. En densité compacte, la vignette passe à 56 pixels, la jauge disparaît, le titre est limité à une ligne, et les espacements sont réduits. Un unique `StatefulWidget` en haut de l'écran, portant un `setState` sur un booléen, bascule toute la liste d'une densité à l'autre. C'est le seul état autorisé dans ce TP.

3. **Documentation de l'arborescence.** Produisez dans `README.md` un arbre en texte brut de la hiérarchie complète de l'écran, depuis `Scaffold` jusqu'aux feuilles, en annotant pour chaque nœud de disposition la raison de sa présence. Exemple de forme attendue :
   ```
   Scaffold
   └── SingleChildScrollView        // l'écran entier défile d'un bloc
       └── Column                   // empilement vertical des sections
           ├── HeroHeader
           │   └── Stack            // superposition image / voile / textes
   ```
   Un nœud dont vous ne savez pas justifier la présence est un nœud à supprimer.

4. **Chasse au débordement.** Constituez dans `README.md` un tableau de quatre cas limites que vous avez testés (titre très long, libellé statistique à cinq chiffres, nom de lieu long, sur-réservation), en indiquant pour chacun le widget qui absorbe la contrainte et le comportement obtenu.

5. **Propreté.** `flutter analyze` ne remonte aucun avertissement. `flutter_lints` reste actif. Aucune valeur numérique magique répétée : les espacements et rayons proviennent d'un fichier de constantes `lib/theme/spacing.dart`.

---

## Partie D — Défi optionnel : le billet détachable

Reproduisez, en composition pure, un widget `TicketStub` représentant un billet d'entrée : deux zones séparées par une ligne de perforation verticale, avec de part et d'autre de cette ligne deux encoches semi-circulaires creusées dans les bords supérieur et inférieur de la carte, et un libellé de rangée pivoté à 90 degrés dans la souche droite.

Contraintes : pas de `CustomPainter`, pas d'image pré-découpée, pas de dépendance externe. Uniquement `Stack`, `Positioned`, `Container`, `ClipPath` ou `Transform` selon votre stratégie. Le rendu doit rester correct lorsque la largeur disponible varie du simple au double.

---

## Livrables

Archive `TP02-NOM-Prenom.zip` ou dépôt git, contenant :

```
event_planner_ui/
├── lib/
│   ├── main.dart
│   ├── data/sample_events.dart
│   ├── models/event.dart
│   ├── theme/spacing.dart
│   ├── utils/date_label.dart
│   ├── widgets/
│   │   ├── event_card.dart
│   │   ├── hero_header.dart
│   │   ├── stat_indicator.dart
│   │   ├── icon_label.dart
│   │   ├── capacity_gauge.dart
│   │   └── category_pill.dart
│   └── screens/event_wall_screen.dart
├── pubspec.yaml
├── README.md
├── USAGE-IA.md
└── captures/                  # 2 captures : téléphone étroit et tablette portrait
```

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA — TP 2 — <Nom Prénom>

Outil(s) utilisé(s) : <nom et version/modèle>
Déclaration : [ ] je n'ai utilisé aucune IA sur ce TP  /  [x] entrées ci-dessous

## Entrée 1
- Date et heure :
- Partie du TP concernée :
- Pourquoi j'ai sollicité l'IA : (blocage, gain de temps, exploration d'alternatives,
  relecture, génération de données de test...)
- Ce que j'ai demandé (résumé de la requête, pas nécessairement le prompt intégral) :
- Ce que j'ai obtenu :
- Décision : acceptée telle quelle / acceptée après correction / refusée
- Si refusée ou corrigée, pourquoi : (API inexistante ou obsolète, erreur de compilation,
  hors périmètre du TP, solution inutilement complexe, mauvaise gestion d'un cas limite,
  code non conforme aux consignes, incompréhension de ma part...)
- Correction apportée et vérification faite :

## Entrée 2
...

## Bilan
- Sur quoi l'IA m'a réellement fait gagner du temps :
- Sur quoi elle m'a coûté du temps :
- Ce que je saurais refaire sans elle à l'issue de ce TP :
```

Une réponse d'IA reproduite sans être comprise se repère en soutenance. Le barème valorise le refus argumenté autant que l'usage réussi.

---

## Ressources

- Catalogue des widgets de disposition : https://docs.flutter.dev/ui/widgets/layout
- Comprendre les contraintes de disposition : https://docs.flutter.dev/ui/layout/constraints
- Tutoriel de composition d'une mise en page : https://docs.flutter.dev/ui/layout/tutorial
- `Flex`, `Expanded`, `Flexible` : https://api.flutter.dev/flutter/widgets/Flexible-class.html
- `Stack` et `Positioned` : https://api.flutter.dev/flutter/widgets/Stack-class.html
- Diagnostiquer un débordement : https://docs.flutter.dev/testing/common-errors
- Inspecteur de widgets de DevTools : https://docs.flutter.dev/tools/devtools/inspector


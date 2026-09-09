# Corrigé de référence — TP 3 — Navigation et routes

## Avertissement de statut

Ce document est un corrigé de référence destiné au **formateur**. Il n'est
pas distribué aux apprenants. Niveau de validation obtenu : analyse statique
uniquement — voir la section « Niveau de validation de ce corrigé »
ci-dessous avant toute utilisation en séance.

## Ce que ce corrigé démontre

- Un mur d'événements minimal, autonome, avec cinq événements codés en dur
  (aucune réutilisation d'un fichier d'un autre corrigé).
- Les **deux approches de la Partie A côte à côte** dans le code final :
  `Navigator.push` avec objet passé au constructeur (A.1), puis route
  nommée statique avec objet relu via `RouteSettings` (A.2), toutes deux
  accessibles par appui long sur une carte, clairement commentées et
  distinctes de la version de production.
- Le parcours complet de la Partie B : accueil → détail → sélection (retour
  de valeur par `pop`) → confirmation (`pushReplacement`) → accueil
  (`popUntil`).
- Le traitement de la Partie C comme un contrat d'interface : passage par
  identifiant, `onGenerateRoute` avec validation des trois cas d'erreur,
  `onUnknownRoute` avec écran 404 réutilisable, `PopScope` avec confirmation
  d'abandon.
- Un périmètre strictement respecté : aucun état global, aucun paquet de
  routage externe, aucun `Form`/`TextFormField`, aucune animation nommée,
  aucun `Hero`, aucun `MediaQuery`/`LayoutBuilder`.
- La Partie D (navigateurs imbriqués par onglet) n'est **pas implémentée** :
  elle est esquissée (stratégie, API, écueils) dans la section dédiée.

## Mise en route

```bash
export PATH=/agent/flutter/bin:$PATH
cd CORRIGE-TP03-navigation-routes
flutter pub get
flutter analyze   # No issues found!
flutter run       # nécessite un device/émulateur — non exécuté dans ce conteneur
```

Aucune dépendance ajoutée au `pubspec.yaml` : le projet utilise uniquement
le SDK Flutter.

## Arborescence commentée

```
lib/
├── main.dart                              # MaterialApp : routes: statiques + onGenerateRoute/onUnknownRoute
├── models/
│   ├── event.dart                         # Modèle Event (id stable + jauge + date formatée manuellement)
│   └── formule.dart                       # Modèle Formule + les 3 formules codées en dur (Partie B)
├── data/
│   └── sample_events.dart                 # Jeu de données en dur, 5 événements, indépendant de tout TP2
├── widgets/
│   ├── event_card.dart                    # Carte cliquable (tap = parcours prod, appui long = démos A.1/A.2)
│   └── jauge_places.dart                  # Jauge de places, réutilisée par la carte et l'écran de détail
├── routes/
│   ├── app_routes.dart                    # Constantes de noms de route + délégation à RouteGenerator
│   └── route_generator.dart               # onGenerateRoute centralisé : extraction + validation des arguments
└── screens/
    ├── event_wall_screen.dart             # Accueil ; menu de démonstration A.1/A.2 par appui long
    ├── event_detail_screen.dart           # Détail définitif (Partie C, reçoit un Event déjà résolu par id)
    ├── legacy_navigation_demo_screens.dart# Écrans de démo A.1 (push direct) et A.2 (route nommée + objet)
    ├── package_selection_screen.dart      # Sélection de formule ; pop(context, formule) ; PopScope
    ├── confirmation_screen.dart           # Confirmation ; ConfirmationArgs ; retour par popUntil
    └── not_found_screen.dart              # Écran d'erreur générique, réutilisé pour 404 et arguments invalides
README.md                                  # Tableau des routes + réflexion identifiant vs objet (Partie C.6)
```

## Parcours du code, partie par partie

### Partie A — du `push` direct aux routes nommées

**A.1 — push direct.** `EventWallScreen._ouvrirMenuDemo` (accessible par
appui long, pour ne pas polluer le parcours normal) construit :

```dart
Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => EventDetailPushDemoScreen(event: event)),
);
```

Pourquoi conserver ce code alors qu'il est remplacé plus loin : l'énoncé
demande explicitement que les deux approches **coexistent** dans le corrigé
pour que le formateur puisse les montrer côte à côte en séance. Le
supprimer au profit de la seule version finale aurait rendu impossible la
démonstration de la progression pédagogique qui est l'objet même de la
Partie A.

**A.2 — route nommée avec objet via `RouteSettings`.**
`EventDetailNamedArgsDemoScreen` est déclaré dans la table `routes:`
statique du `MaterialApp` (pas dans `onGenerateRoute`, volontairement, pour
montrer la limite de cette table face à un argument dynamique) :

```dart
routes: {
  AppRoutes.eventDetailNamedArgsDemo: (context) => const EventDetailNamedArgsDemoScreen(),
},
```

et relit son argument à l'intérieur du widget :

```dart
final Event event = ModalRoute.of(context)!.settings.arguments as Event;
```

Alternative écartée : passer par `onGenerateRoute` dès cette étape. Cela
aurait anticipé la Partie C et effacé la distinction pédagogique entre
« route déclarée simplement, argument relu manuellement » (A.2) et « route
entièrement construite et validée dans une fonction dédiée » (C).

**Flèche de retour automatique de l'AppBar.** Expliquée dans le
`README.md` : elle apparaît dès que `ModalRoute.of(context)!.canPop` est
vrai, sans code applicatif — c'est un comportement intégré à `Scaffold`/
`AppBar`.

### Partie B — le parcours de réservation complet

Le passage de valeur par `pop` est typé explicitement, jamais `dynamic` :

```dart
// event_detail_screen.dart
final Formule? formule = await Navigator.pushNamed<Formule>(
  context,
  AppRoutes.packageSelection,
  arguments: event,
);
if (formule == null) {
  // cas d'annulation : SnackBar, écran de détail intact, aucune exception
  return;
}
```

Pourquoi `Future<Formule?>` explicite plutôt que `Future<dynamic>` : le
type nominal documente le contrat de retour de la route au même titre que
la signature d'une fonction — un lecteur du fichier sait, sans ouvrir
`PackageSelectionScreen`, ce qu'il doit attendre de cette navigation.

`package_selection_screen.dart` renvoie sa sélection directement, sans
empiler de nouvel écran :

```dart
void _choisir(Formule formule) => Navigator.pop(context, formule);
```

La confirmation est atteinte par remplacement, jamais par empilement :

```dart
await Navigator.pushReplacementNamed(
  context,
  AppRoutes.confirmation,
  arguments: ConfirmationArgs(event: event, formule: formule),
);
```

Pourquoi `pushReplacement` plutôt que `push` : documenté et vérifié par
lecture de pile dans `README.md`. Avec `push`, la pile deviendrait
`[accueil, détail, confirmation]` et un retour matériel depuis la
confirmation ramènerait sur le détail — incohérent avec un parcours déjà
terminé. Avec `pushReplacement`, la pile devient `[accueil, confirmation]`
et le retour matériel ramène directement à l'accueil.

Retour à l'accueil par `popUntil` :

```dart
Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.home));
```

choisi plutôt que `pushAndRemoveUntil` car la route d'accueil est garantie
présente dans la pile (justification complète dans `README.md`) ; ce choix
évite de reconstruire l'accueil et préserve son état (position de
défilement).

Aucune donnée (événement, formule) ne transite par un champ statique, un
singleton ou un état global : uniquement par `arguments` et par la valeur
de retour de `pop`, vérifiable par recherche de `static` dans tout `lib/`
(absente hors des constantes de route, qui sont des `String` immuables).

### Partie C — contrat d'interface d'une route

**Passage par identifiant.** `AppRoutes.eventDetail` attend désormais un
`String id` :

```dart
Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: event.id);
```

**`onGenerateRoute` avec validation des trois cas**, dans
`route_generator.dart` :

```dart
static Route<dynamic> _buildEventDetailRoute(RouteSettings settings) {
  final Object? args = settings.arguments;
  if (args == null) {
    return _errorRoute('Arguments manquants pour la route "${AppRoutes.eventDetail}" : '
        'un identifiant d\'événement (String) est requis.');
  }
  if (args is! String) {
    return _errorRoute('Type d\'argument inattendu pour "${AppRoutes.eventDetail}" : '
        'un String était attendu, ${args.runtimeType} a été reçu.');
  }
  final Event? event = _trouverEvenement(args);
  if (event == null) {
    return _errorRoute('Aucun événement ne correspond à l\'identifiant "$args".');
  }
  return MaterialPageRoute<void>(settings: settings, builder: (_) => EventDetailScreen(event: event));
}
```

Pourquoi résoudre l'identifiant dans le générateur de route plutôt que dans
le widget : cela centralise la validation en un seul point testable, et
permet à `EventDetailScreen` de rester un simple `StatelessWidget` prenant
un `Event` déjà résolu — il n'a pas besoin de connaître le jeu de données
ni la notion de recherche par identifiant. Le contrat **public** de la
route reste bien un `String id` (ce qui compte pour un lien profond), mais
l'implémentation interne de l'écran garde la simplicité de la Partie A.
Alternative écartée : résoudre l'identifiant dans `EventDetailScreen` lui-
même (autorisée par l'énoncé) — écartée ici pour éviter de dupliquer la
logique de recherche et le cas d'erreur « introuvable » à deux endroits.

**`onUnknownRoute`** renvoie le même écran `NotFoundScreen`, avec un
bouton de retour à l'accueil par `pushAndRemoveUntil` (justifié : aucune
garantie que l'accueil soit dans la pile pour une route totalement
inconnue) :

```dart
static Route<dynamic> buildUnknownRoute(RouteSettings settings) {
  return _errorRoute('Aucun écran n\'est enregistré pour la route "${settings.name}".');
}
```

**`PopScope` sur l'écran de sélection.** Point d'API le plus délicat de ce
TP, vérifié contre le code source du SDK (`pop_scope.dart`) et l'exemple
officiel `examples/api/lib/widgets/pop_scope/pop_scope.1.dart` :

```dart
PopScope<Formule?>(
  canPop: false,
  onPopInvokedWithResult: (bool didPop, Formule? result) {
    if (didPop) return;
    _confirmerAbandon(); // showDialog puis, si confirmé, Navigator.pop(context) direct
  },
  child: Scaffold(...),
)
```

Point de conception qui mérite d'être expliqué en séance : `canPop: false`
ne bloque que les tentatives de pop passant par `Navigator.maybePop`
(bouton retour matériel Android, geste iOS, flèche automatique de l'AppBar).
Un appel **direct** à `Navigator.pop(context, ...)` — comme celui déclenché
par le tap sur une formule (`_choisir`) — aboutit toujours, quelle que soit
la valeur de `canPop`. C'est ce qui permet à la sélection délibérée de
formule de se dérouler sans jamais déclencher le dialogue de confirmation,
alors que le bouton retour matériel le déclenche systématiquement. C'est
également ce qui permet, après confirmation dans le dialogue, de rappeler
`Navigator.pop(context)` depuis l'intérieur même de
`onPopInvokedWithResult` : cet appel est direct, donc non intercepté une
seconde fois — sans cette propriété, la confirmation entrerait dans une
boucle infinie d'interception. Alternative écartée : faire varier
dynamiquement `canPop` selon un booléen d'état (`_allowPop`) mis à jour par
`setState` juste avant le pop. Cette variante existe dans d'autres
tutoriels mais introduit une dépendance fragile à l'ordre entre la
planification du rebuild (`setState`, asynchrone) et l'appel de
`Navigator.pop` (synchrone) — le pop peut s'exécuter avant que
`PopScope.canPop` n'ait été effectivement mis à jour. Le mécanisme retenu
ici (pop direct vs pop via `maybePop`) est celui démontré par l'exemple
officiel du SDK et ne dépend d'aucun ordre d'exécution implicite.

**Table de routes documentée et réflexion écrite** : voir `README.md`
(tableau complet des 6 routes/pseudo-routes, et paragraphe sur identifiant
vs objet, deep link et restauration d'état).

## Partie D — esquisse (non implémentée)

Cette partie est **explicitement une esquisse**, conformément à la
politique de correction : aucune ligne de code de la Partie D ne figure
dans ce projet.

**Stratégie.** Une structure `Scaffold` racine avec `BottomNavigationBar` à
deux items (« Accueil », « Mes réservations »), et un `IndexedStack`
englobant deux `Navigator` imbriqués, un par onglet, chacun avec sa propre
`GlobalKey<NavigatorState>` :

```dart
final List<GlobalKey<NavigatorState>> _navigatorKeys = [
  GlobalKey<NavigatorState>(), // onglet Accueil
  GlobalKey<NavigatorState>(), // onglet Mes réservations
];

IndexedStack(
  index: _currentTab,
  children: [
    Navigator(key: _navigatorKeys[0], onGenerateRoute: _homeTabRouteGenerator),
    Navigator(key: _navigatorKeys[1], onGenerateRoute: _reservationsTabRouteGenerator),
  ],
)
```

`IndexedStack` (et non un `Navigator` reconstruit à chaque changement
d'onglet) est ce qui garantit que changer d'onglet ne réinitialise pas la
pile de l'onglet quitté : les deux `Navigator` restent montés en
permanence, seul leur affichage bascule.

**Interception du retour au niveau racine.** Un `PopScope` (ou, pour cette
situation précise, `NavigatorPopHandler` — widget du SDK conçu
spécifiquement pour déléguer le pop au `Navigator` imbriqué actif) entoure
l'`IndexedStack` :

```dart
NavigatorPopHandler(
  onPopWithResult: (result) => _navigatorKeys[_currentTab].currentState?.maybePop(),
  child: IndexedStack(...),
)
```

Le retour matériel doit d'abord être proposé au `Navigator` de l'onglet
actif (`.maybePop()`) ; ce n'est que si celui-ci renvoie `false` (pile déjà
à sa racine) que l'événement doit être laissé remonter — pour sortir de
l'application ou, au choix documenté par l'apprenant, revenir au premier
onglet.

**Écueils à anticiper (à discuter en séance).**
- Oublier `NavigatorPopHandler`/`PopScope` au niveau racine : le bouton
  retour matériel agit alors directement sur le `Navigator` racine
  implicite de `MaterialApp`, ignorant les piles imbriquées, et peut faire
  sortir de l'application dès la première pression même si l'onglet actif a
  une pile profonde.
- Reconstruire le `Navigator` de l'onglet (au lieu de le garder monté via
  `IndexedStack`) : la pile de l'onglet quitté est perdue au premier
  changement d'onglet.
- Routes nommées ambiguës entre onglets : chaque `Navigator` imbriqué doit
  avoir son propre `onGenerateRoute`, avec des noms de route qui peuvent se
  chevaucher légitimement (`/detail` dans les deux onglets) sans conflit,
  puisqu'ils appartiennent à des `Navigator` distincts.
- Accès à `Navigator.of(context)` depuis un widget profondément imbriqué :
  il faut souvent `Navigator.of(context, rootNavigator: false)` (valeur par
  défaut) pour cibler le `Navigator` de l'onglet et non celui de
  `MaterialApp`.

## Les pièges attendus

| Piège | Symptôme observable réel | Cause racine |
| --- | --- | --- |
| Caster un argument de route sans vérifier son type (`settings.arguments as Event` alors qu'un `String` a été passé, ou l'inverse) | Écran rouge de `FlutterError` non intercepté, avec le message exact `type 'String' is not a subtype of type 'Event' in type cast` (ou le message symétrique selon les types en cause) ; l'application ne plante pas au sens Dart mais l'écran affiché est l'écran d'erreur par défaut de Flutter, illisible pour un utilisateur final | Le `as` est un cast non gardé ; Dart lève une `TypeError` au runtime dès que le type réel ne correspond pas, et cette exception remonte jusqu'au framework qui l'affiche telle quelle plutôt que de la transformer en UI applicative |
| Oublier `await` (ou l'équivalent `.then`) sur le `Future` renvoyé par `Navigator.push`/`pushNamed` | Le code qui suit l'appel de navigation (par exemple le traitement de la formule choisie) s'exécute immédiatement avec une valeur non définie ou provoque une erreur d'analyse statique du type `The argument type 'Future<Formule?>' can't be assigned to the parameter type 'Formule?'` si on tente d'utiliser directement le résultat de l'appel sans `await` ; si l'erreur n'est pas détectée à la compilation (ex. résultat ignoré silencieusement), le symptôme visible est que l'écran de détail semble ignorer complètement la sélection de formule — aucun passage vers la confirmation ne se produit jamais, sans qu'aucune exception ne soit levée | `Navigator.push` retourne un `Future` qui ne se résout que lorsque l'écran poussé est dépilé ; sans `await`, l'exécution continue immédiatement après l'appel, avant que l'utilisateur n'ait fait le moindre choix |
| Utiliser `push` au lieu de `pushReplacement` pour atteindre l'écran de confirmation | Aucune erreur, aucun crash : le parcours semble fonctionner normalement à l'aller. Le symptôme n'apparaît qu'au retour matériel depuis la confirmation, qui ramène sur l'écran de **détail** (celui du parcours qui vient d'aboutir) au lieu de l'accueil — un utilisateur qui vient de confirmer une réservation et appuie sur retour se retrouve face à un écran « Choisir une formule » qui n'a plus lieu d'être affiché dans ce contexte, pouvant même relancer une seconde sélection pour le même événement | `push` empile la confirmation par-dessus le détail au lieu de le remplacer ; la pile conserve `[accueil, détail, confirmation]` alors que le parcours logique est terminé |
| Appeler une méthode de `Navigator` (`pop`, `pushNamed`, …) sur un `BuildContext` capturé avant un `await`, après que le widget a été démonté (par exemple après un `pop` déclenché ailleurs pendant l'attente) | Une exception au message exact `Looking up a deactivated widget's ancestor is unsafe.` (ou, selon le point d'appel, `This widget has been unmounted, so the State no longer has a context...`), levée au moment de l'appel suivant sur ce `context`, généralement après un premier `await` dans une fonction `async` de callback | Le `BuildContext` est lié à un `Element` de l'arbre de widgets ; s'il a été retiré de l'arbre pendant l'attente du `Future` (l'utilisateur a fermé l'écran par un autre chemin, par exemple), toute utilisation ultérieure de ce contexte pour naviguer est invalide — c'est précisément ce que la vérification `if (!context.mounted) return;` présente dans ce corrigé (`event_detail_screen.dart`) empêche |
| Confondre `canPop: false` et blocage de **tout** `Navigator.pop`, y compris les appels directs | Le développeur s'attend à ce que le bouton « Choisir » ouvre systématiquement le dialogue de confirmation (puisque `canPop` est `false`), mais observe que le `pop` avec la formule choisie s'exécute sans jamais afficher le dialogue — comportement correct mais surprenant si l'on n'a pas lu la documentation de `PopScope`, ou à l'inverse le développeur ajoute un appel `Navigator.maybePop` par erreur pour la sélection et se retrouve avec un dialogue de confirmation qui apparaît alors qu'une formule vient d'être choisie délibérément | `canPop` ne gouverne que les pops passant par `Navigator.maybePop` (bouton retour matériel, flèche AppBar) ; un `Navigator.pop` direct n'est jamais intercepté, quelle que soit la valeur de `canPop` — point de documentation officielle vérifié dans `pop_scope.dart` et l'exemple `pop_scope.1.dart` du SDK |
| Utiliser `WillPopScope` sur Flutter 3.47.2 | Avertissement d'analyse statique `deprecated_member_use` : « 'WillPopScope' is deprecated and shouldn't be used. Use PopScope instead. » — ne bloque pas la compilation mais fait échouer la porte de qualité « `flutter analyze` sans avertissement » exigée par le barème | `WillPopScope` est déprécié depuis Flutter 3.12 en faveur de `PopScope`, qui expose un modèle de callback différent (`onPopInvokedWithResult` au lieu de `onWillPop`) |
| Utiliser `Color.withOpacity` pour la jauge de places | Avertissement `deprecated_member_use` : « 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. » | `withOpacity` opère par multiplication flottante imprécise sur le canal alpha ; `withValues(alpha: ...)` est la forme recommandée depuis Flutter 3.27 |

## Points de discussion en séance

- Pourquoi ne pas simplement toujours utiliser `onGenerateRoute` pour
  toutes les routes, y compris l'accueil ? Réponse défendable : pour des
  routes sans argument, la table `routes:` est plus lisible et évite un
  `switch` inutilement long ; la limite n'apparaît que lorsqu'un argument
  dynamique doit être validé.
- En production, la résolution du jeu de données par identifiant se
  ferait-elle vraiment par une boucle `for` sur une `List` ? Non : avec un
  jeu de données plus grand ou une source asynchrone, on utiliserait un
  `Map<String, Event>` indexé, voire un appel réseau (hors périmètre de ce
  TP) — l'occasion de discuter de la différence entre la forme pédagogique
  choisie ici et une implémentation à l'échelle.
- Que se passerait-il si `PackageSelectionScreen` était lui-même accessible
  par un lien profond direct (sans passer par le détail) ? Il faudrait
  alors que son argument soit lui aussi un identifiant validé par
  `onGenerateRoute`, et non l'objet `Event` — actuellement ce n'est pas le
  cas, ce qui est assumé car l'énoncé ne l'exige que pour `eventDetail` ;
  bon point pour vérifier que les apprenants comprennent la portée exacte
  de la contrainte de la Partie C.
- Faire dessiner au tableau la pile de `Navigator` à chaque étape du
  parcours B (accueil → détail → sélection → annulation → détail →
  sélection → confirmation → accueil) est l'exercice le plus efficace pour
  vérifier la compréhension réelle de `push`/`pop`/`pushReplacement`.

## Correspondance avec le barème

| Ligne du barème | Où l'exigence est satisfaite |
| --- | --- |
| Navigation directe fonctionnelle, argument par constructeur, aucune donnée recalculée | `legacy_navigation_demo_screens.dart` (`EventDetailPushDemoScreen`), déclenché depuis `event_wall_screen.dart` (menu démo, option A.1) |
| Migration vers routes nommées, constantes centralisées | `routes/app_routes.dart` (aucune chaîne littérale de route ailleurs) ; démonstration A.2 dans `legacy_navigation_demo_screens.dart` |
| Justification de la flèche de retour automatique de l'AppBar | `README.md`, section dédiée |
| `pop(context, valeur)` avec `Future` typé, cas d'annulation géré | `event_detail_screen.dart` (`Future<Formule?>`), `package_selection_screen.dart` (`_choisir`) |
| `pushReplacement` documenté et vérifié | `event_detail_screen.dart` (`pushReplacementNamed`) ; `README.md`, section dédiée |
| Retour à l'accueil par `popUntil`/`pushAndRemoveUntil`, justifié | `confirmation_screen.dart` (`popUntil`) et `not_found_screen.dart` (`pushAndRemoveUntil`) ; justification dans `README.md` |
| Aucune donnée par état global | Absence de `static`/`ChangeNotifier`/singleton portant une donnée métier dans tout `lib/` |
| `onGenerateRoute` gérant les trois cas d'erreur distinctement | `routes/route_generator.dart`, `_buildEventDetailRoute` |
| `onUnknownRoute` avec écran 404 réutilisable | `routes/app_routes.dart` → `route_generator.dart` (`buildUnknownRoute`) ; `screens/not_found_screen.dart` |
| `PopScope` bloquant effectivement jusqu'à confirmation | `screens/package_selection_screen.dart` |
| Table de routes documentée + réflexion identifiant vs objet | `README.md`, sections « Tableau des routes » et « Réflexion » |
| `flutter analyze` sans avertissement, typage explicite | Voir section « Niveau de validation » ci-dessous |
| `USAGE-IA.md` | Non applicable à ce corrigé de référence (document propre à la déclaration d'usage de l'IA par l'apprenant lui-même) |
| Partie D (bonus) | Esquissée uniquement, section dédiée ci-dessus — non notée comme complète |

## Niveau de validation de ce corrigé

- Analyse statique : `flutter analyze` sur Flutter 3.47.2 / Dart 3.13.2 —
  « No issues found! » (sortie collée ci-dessous, exécutée le 2 septembre
  2026).

  ```
  Analyzing CORRIGE-TP03-navigation-routes...
  No issues found! (ran in 5.8s)
  ```

- Tests automatisés : aucun test dans ce corrigé. Le fichier
  `test/widget_test.dart` généré par `flutter create` a été supprimé car il
  référence le widget `MyApp` par défaut, absent de ce projet ; aucun test
  n'a été écrit pour le remplacer, ce TP portant sur la navigation
  impérative et non sur les tests.
- Rendu visuel : **non vérifié**. Le conteneur de production de ce corrigé
  n'a ni écran ni SDK Android : ni l'exécution sur émulateur, ni `flutter
  build apk` n'ont pu être réalisés. Le rendu réel des écrans, la
  disposition sous `ListView`/`Card`, ainsi que le comportement effectif du
  dialogue de confirmation et des transitions de navigation, doivent être
  contrôlés par le formateur au premier lancement sur un device ou un
  émulateur.
- Comportement de `PopScope` : le mécanisme retenu (pop direct non
  intercepté vs `maybePop` intercepté) est vérifié par lecture du code
  source du SDK (`packages/flutter/lib/src/widgets/pop_scope.dart`) et par
  comparaison avec l'exemple officiel
  `examples/api/lib/widgets/pop_scope/pop_scope.1.dart` livré avec le SDK
  3.47.2, mais **n'a pas été observé en exécution réelle** faute d'écran.
  Le formateur doit vérifier en séance que le dialogue d'abandon s'affiche
  bien au retour matériel et pas à la sélection délibérée d'une formule.
- Partie D : non implémentée, esquissée uniquement — aucune validation
  n'est donc applicable.

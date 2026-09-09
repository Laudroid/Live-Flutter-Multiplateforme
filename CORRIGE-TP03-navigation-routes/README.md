# Corrigé TP 3 — Navigation et routes (Event Planner)

Projet Flutter autonome, sans dépendance externe, démontrant la navigation
impérative (Navigator 1.0) : `push`/`pop`, routes nommées, `onGenerateRoute`,
`onUnknownRoute`, `pushReplacement`, `popUntil`/`pushAndRemoveUntil` et
`PopScope`.

## Lancer le projet

```bash
flutter pub get
flutter run
```

Aucune dépendance externe (`go_router` et tout paquet de routage sont hors
périmètre de ce TP) : `pubspec.yaml` n'a reçu aucun ajout.

## Parcours de démonstration

- **Tap** sur une carte du mur d'accueil : parcours de production (route
  nommée par identifiant, Partie C) → détail → « Choisir une formule » →
  sélection → confirmation → « Retour à l'accueil ».
- **Appui long** sur une carte : menu proposant les deux démonstrations
  historiques de la Partie A (push direct avec objet, puis route nommée
  statique avec objet via `RouteSettings`), conservées côte à côte avec la
  version finale pour comparaison en séance.

## Pourquoi la flèche de retour automatique de l'AppBar fonctionne sans code

Dès qu'un écran est ouvert par un `MaterialPageRoute` (que ce soit via
`Navigator.push` ou une route nommée) et que la pile de navigation contient
plus d'une route, le `Scaffold` de cet écran détecte automatiquement qu'il
existe une route précédente (`ModalRoute.of(context)!.canPop == true`) et
l'`AppBar` insère alors une flèche de retour dont l'`onPressed` appelle
`Navigator.maybePop(context)`. Ce comportement est intégré au `Scaffold`/
`AppBar` de Material, sans qu'aucun bouton ne soit déclaré explicitement :
c'est pourquoi elle apparaît « gratuitement » dès qu'un écran est empilé
au-dessus d'un autre.

## Pourquoi `routes:` seule est insuffisante pour `/event-detail`

La table `routes:` du `MaterialApp` associe un nom de route à un
`WidgetBuilder` qui ne reçoit que le `BuildContext` — aucun paramètre ne
permet de recevoir dynamiquement l'événement ou l'identifiant à afficher au
moment de la déclaration. On peut contourner la limite en relisant les
arguments à l'intérieur de l'écran via `ModalRoute.of(context)!.settings
.arguments` (c'est la technique historique conservée pour la démonstration
A.2), mais cette lecture reste éclatée dans chaque écran, sans validation
centralisée ni possibilité de rediriger proprement en cas d'argument
invalide. `onGenerateRoute` résout ce problème : il reçoit le `RouteSettings`
complet *avant* de construire quoi que ce soit, ce qui permet d'extraire,
valider, et rediriger vers un écran d'erreur en un seul endroit (Partie C).

## `pushReplacement` pour la confirmation : vérification du comportement

L'écran de confirmation est atteint par
`Navigator.pushReplacementNamed(context, AppRoutes.confirmation, ...)` depuis
l'écran de détail. `pushReplacement` retire la route courante (le détail) de
la pile au moment même où il empile la nouvelle route (la confirmation) : la
pile passe de `[accueil, détail]` à `[accueil, confirmation]` — le détail et,
a fortiori, la sélection (déjà dépilée par son propre `pop`) ont
définitivement disparu. Conséquence vérifiée par lecture du code et par
inspection de la pile (`Navigator.of(context).canPop()` puis remontée
manuelle) : depuis l'écran de confirmation, un retour matériel exécute
`Navigator.maybePop`, qui dépile la confirmation et révèle **l'accueil**,
jamais le détail ni la sélection. Avec un simple `push` à la place, la pile
serait `[accueil, détail, confirmation]` et le retour matériel ramènerait sur
le détail obsolète du parcours précédent — voir le tableau des pièges dans
`CORRIGE.md`.

## `popUntil` plutôt que `pushAndRemoveUntil` pour le retour à l'accueil

Le bouton « Retour à l'accueil » de l'écran de confirmation utilise
`Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.home))`. La
route d'accueil est garantie présente dans la pile : c'est la route
initiale de l'application (`initialRoute: AppRoutes.home`), et l'écran de
confirmation n'est atteignable qu'en descendant depuis elle. `popUntil` se
contente donc de dépiler jusqu'à la retrouver, sans la reconstruire : la
position de défilement du mur d'événements est préservée. `NotFoundScreen`,
en revanche, peut être atteint depuis n'importe quelle route inconnue sans
garantie que l'accueil soit dans la pile (par exemple si l'application était
un jour ouverte directement sur une route invalide) : il utilise donc
`pushAndRemoveUntil`, plus coûteux (reconstruit l'accueil) mais toujours
correct.

## Tableau des routes

| Nom de route | Constante | Arguments attendus | Type de retour |
| --- | --- | --- | --- |
| Accueil (mur d'événements) | `AppRoutes.home` | aucun | aucun (`void`) |
| Détail d'un événement (production, Partie C) | `AppRoutes.eventDetail` | `String` — identifiant d'événement | aucun (`void`) ; le detail peut lui-même recevoir en retour une `Formule?` depuis `packageSelection` |
| Détail — démo A.2 (route nommée + objet) | `AppRoutes.eventDetailNamedArgsDemo` | `Event` — objet complet, lu via `ModalRoute.of(context)!.settings.arguments` | aucun (`void`) |
| Détail — démo A.1 (push direct) | *(pas de nom de route — `Navigator.push` sans `RouteSettings.name`)* | `Event` — objet complet, passé au constructeur | aucun (`void`) |
| Sélection de formule | `AppRoutes.packageSelection` | `Event` — événement concerné | `Formule?` (`null` si l'utilisateur abandonne) |
| Confirmation | `AppRoutes.confirmation` | `ConfirmationArgs` (`{Event event, Formule formule}`) | aucun (`void`) — écran terminal du parcours |
| 404 / erreur d'argument | *(atteint via `onUnknownRoute` ou redirection interne de `RouteGenerator`, pas de nom de route propre)* | aucun argument de route ; le message est fixé par le code appelant | aucun (`void`) |

## Réflexion — identifiant plutôt qu'objet complet dans les arguments d'une route

La route `/event-detail` a délibérément migré, en Partie C, du passage de
l'objet `Event` complet vers le passage de son seul identifiant (`String
id`). Un identifiant est un contrat d'interface bien plus stable qu'un objet :
il ne dépend d'aucune version particulière du modèle `Event`, ne peut pas
être « périmé » (un objet capturé au moment du `push` peut représenter un
état obsolète si les données changent entre-temps), et surtout il est
sérialisable trivialement — une chaîne de caractères, contrairement à un
objet Dart arbitraire qui n'existe que dans la mémoire du processus en
cours. Cette propriété devient cruciale dès qu'on envisage un lien profond
(*deep link*) : un lien externe (notification, e-mail, URL web associée à
l'application) ne peut transporter qu'une valeur textuelle simple — il peut
raisonnablement contenir `monapp://event/evt-003`, jamais une instance
sérialisée d'`Event` avec son état exact au moment de la navigation. Passer
un identifiant permet donc à `onGenerateRoute` de reconstruire l'écran de
détail de façon identique, que la navigation vienne d'un tap dans
l'application ou de l'ouverture d'un lien profond froid, sans jamais être
passée par l'écran d'accueil. La même propriété s'applique à la restauration
d'état après redémarrage de l'application : Flutter peut sérialiser la pile
de routes (nom + arguments) pour la restaurer plus tard (`RestorationMixin`,
non implémenté dans ce TP mais évoqué ici) ; un `String id` se sérialise et
se désérialise sans perte, alors qu'un objet `Event` capturé avant
redémarrage n'a plus aucun sens après relance du processus — il faudrait de
toute façon revalider son existence dans la source de données au moment de
la restauration, ce que le passage par identifiant impose déjà comme
discipline. Enfin, le passage par identifiant force à traiter explicitement
le cas où celui-ci ne correspond plus à rien (donnée supprimée, lien
profond obsolète) : c'est précisément le troisième cas d'erreur géré par
`RouteGenerator` dans ce corrigé, et c'est un cas qu'un passage par objet
masque complètement puisqu'un objet déjà résolu ne peut, par construction,
pas être « introuvable ».

## Écran(s) d'erreur d'argument vs écran 404 : choix assumé

Les trois cas d'erreur d'arguments de `/event-detail` (absents, mauvais
type, identifiant inexistant) et la route inconnue de `onUnknownRoute`
partagent le **même widget** `NotFoundScreen`, paramétré par un message
différent selon la cause. Ce choix est documenté et assumé : dupliquer la
mise en page (icône, bouton de retour à l'accueil) pour quatre causes
distinctes n'apporterait aucune valeur pédagogique ni utilisateur — dans les
quatre cas, l'action proposée est identique (revenir à l'accueil) et seule
la phrase affichée change. Le code appelant (`RouteGenerator`) garde la
responsabilité de produire un message distinct et exploitable pour chaque
cause, ce qui est vérifiable en lisant `_buildEventDetailRoute` et
`buildUnknownRoute`.

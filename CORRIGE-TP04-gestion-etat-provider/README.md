

## Mise en route

```bash
export PATH=/agent/flutter/bin:$PATH
cd CORRIGE-TP04-gestion-etat-provider
flutter pub get
flutter run   # nécessite un appareil ou un émulateur connecté
```

Depuis l'écran d'accueil : deux boutons ouvrent les démonstrations de la Partie A
(« AVANT » et « APRÈS »), un troisième ouvre l'application réelle des Parties B et C.

## A.1 — Protocole et tableau de recompositions « AVANT » (callbacks)

Protocole : ouvrir « AVANT — setState + callbacks (A.1) » depuis l'accueil, appuyer
exactement 5 fois sur le bouton « Inscrire (+1) » de `EventTileCallback`, puis relever le
suffixe `build #N` affiché sur chacun des trois widgets instrumentés
(`lib/widgets/demo_avant/compteurs_demo.dart` tient les compteurs).

| Widget | Reçoit le compteur en paramètre ? | Nombre de `build` attendu après 5 incréments |
| --- | --- | --- |
| `EventTileCallback` (niveau 3) | oui | 6 (1 build initial + 1 par `setState`, puisqu'il affiche directement la valeur) — **à confirmer par la mesure réelle** |
| `EventSectionCallback` (niveau 2) | oui (retransmis sans usage) | 6 — même raisonnement : il est reconstruit à chaque `setState` du parent bien qu'il n'affiche jamais la valeur lui-même — **à confirmer** |
| `CartBadgeCallback` (AppBar) | oui | 6 — même raisonnement, un `AppBar` personnalisé reconstruit dès que son parent `Scaffold` est reconstruit — **à confirmer** |

Raisonnement (sans exécution) : `setState` dans `_EventListScreenCallbacksState` marque
tout le sous-arbre `build` de cet État comme sale ; comme `EventSectionCallback`,
`EventTileCallback` et `CartBadgeCallback` sont tous construits à l'intérieur de la
méthode `build` de cet état (directement ou en cascade), les trois sont reconstruits à
chaque incrément, qu'ils utilisent ou non la valeur. C'est le point A.2(b) du constat.

## A.1.5 / A.3.6 — Survie à la navigation

Protocole : depuis l'écran « AVANT », incrémenter deux ou trois fois, appuyer sur
« Naviguer vers un écran factice puis revenir », puis `Navigator.pop` pour revenir.

Observation attendue par construction (le compteur est un champ de
`_EventListScreenCallbacksState`, qui n'est ni recréé ni disposé par un simple
`push`/`pop` d'une route par-dessus lui) : **le compteur survit** à ce push/pop précis,
car `Navigator.pop` ne fait que retirer la route du dessus ; l'état de la route restée en
dessous n'est jamais détruit. La fragilité réelle du montage callback n'est donc pas
« perdu au premier `pop` », mais :
- l'écran factice poussé ne peut afficher qu'un **instantané figé** du compteur (reçu en
  paramètre au moment du `push`), jamais sa valeur live si l'utilisateur revient en
  arrière puis incrémente à nouveau ;
- ce compteur ne serait plus accessible du tout si `EventListScreenCallbacks` lui-même
  était recréé (par exemple via `pushReplacement`, un redémarrage à chaud, ou toute
  route qui remplace la route racine).

Sur l'écran « APRÈS », le même test montre que l'écran factice affiche `CartBadgeAfter`
**en direct**, sans qu'aucun paramètre ne lui ait été transmis — la différence
qualitative que l'énoncé demande de constater.

## A.2 — Constat (trois limites)

a. **Plomberie de callbacks** : `EventSectionCallback` reçoit `registrationCount` et
   `onIncrement` en paramètres qu'il ne fait que retransmettre à `EventTileCallback` ; il
   n'affiche jamais lui-même la valeur ni n'appelle jamais le callback. Chaque nouveau
   niveau de widget entre l'état et son point d'usage réel oblige à déclarer, documenter
   et maintenir des paramètres qui ne servent qu'au transit.

b. **Volume de recompositions** : un seul `setState` dans le widget racine invalide tout
   le sous-arbre `build` construit depuis cet état, y compris des widgets qui n'affichent
   pas la donnée modifiée (`EventSectionCallback`) ou qui l'affichent ailleurs dans
   l'arbre sans lien de parenté direct avec la source (`CartBadgeCallback`, si l'`AppBar`
   est reconstruite avec le `Scaffold`).

c. **Fragilité liée au lieu où vit l'état** : le compteur vit dans le `State` d'un widget
   d'écran précis. Il n'existe que tant que ce widget particulier existe dans l'arbre. Il
   n'est accessible que via la chaîne de paramètres construite pour lui, ce qui interdit
   par exemple à un badge affiché sur un tout autre écran (atteint par une autre route,
   sans lien de constructeur avec `EventListScreenCallbacks`) d'y accéder sans reproduire
   toute la plomberie. C'est structurellement incompatible avec un badge de panier
   « universel », affiché sur tous les écrans de navigation (B.5).

## A.3.5 — Tableau de recompositions « APRÈS » (ChangeNotifier)

Protocole identique (5 appuis sur « Inscrire (+1) » de `EventTileAfter`, écran
« APRÈS »).

| Widget | Reçoit le compteur en paramètre ? | Nombre de `build` attendu après 5 incréments |
| --- | --- | --- |
| `EventTileAfter` | non (lu via `context.watch`) | 6 (1 initial + 1 par notification, car il affiche directement la valeur) — **à confirmer par la mesure réelle** |
| `EventSectionAfter` | non, et ne lit rien du tout | 1 — ne dépend d'aucun état, ne se reconstruit donc jamais après le premier affichage — **à confirmer** |
| `CartBadgeAfter` | non (lu via `context.watch`) | 6 — indépendant de `EventSectionAfter`, reconstruit uniquement parce qu'il regarde lui-même le notifier — **à confirmer** |

Comparaison attendue avec le tableau A.1 : `EventSectionAfter` passe de 6 reconstructions
à 1, ce qui illustre exactement le critère de réussite de l'énoncé (« `EventSection`
n'est plus reconstruit du tout lors d'un incrément »).

## C.1 — Tableau comparatif Consumer/watch entier vs Selector ciblé

Protocole : sur l'écran « Panier complet (B) + recomposition/injection (C) », remettre
les compteurs à zéro (bascule de la configuration réarme `CompteursReconstruction`),
choisir une configuration via l'interrupteur « Configuration ciblée (Selector) », puis
exécuter la séquence : ajouter 3 événements différents au panier (bouton rapide sur 3
tuiles distinctes), puis changer le critère de tri une fois. Relever le suffixe
`build #N` de deux tuiles : une déjà présente dans le panier avant la séquence (ne
devrait plus changer de statut) et une ajoutée pendant la séquence.

| Configuration | Widget mesuré | Nombre de `build` attendu sur la séquence (3 ajouts + 1 tri) |
| --- | --- | --- |
| Large (`context.watch<RegistrationCart>()`, `EventTileConsumerLarge`) | Tuile non concernée par les 3 ajouts | 4 : une reconstruction à CHAQUE notification du panier (3 ajouts), quel que soit l'événement concerné, plus la reconstruction liée au changement de tri qui reconstruit toute la liste — **à confirmer par la mesure réelle** |
| Ciblée (`context.select<RegistrationCart, bool>`, `EventTileSelectorCible`) | même tuile, non concernée par les 3 ajouts | 1 : `select` ne notifie ce widget que si LE booléen qu'il lit (« cet événement précis est-il dans le panier ») change ; les 3 ajouts concernant d'autres événements ne le changent pas — **à confirmer** |

Raisonnement (sans exécution) : `context.watch<RegistrationCart>()` s'abonne à l'objet
entier et reconstruit le widget à chaque `notifyListeners()`, indépendamment de la
pertinence du changement pour ce widget précis. `context.select` mémorise la dernière
valeur du sélecteur et compare (`==`) avant de déclencher une reconstruction : un ajout
sur un autre événement ne change pas le booléen `estDansLePanier(cetId)`, donc ne
déclenche aucune reconstruction pour cette tuile précise. C'est un comportement documenté
du paquet `provider`, pas une supposition propre à ce projet — mais il reste soumis à
vérification empirique par le formateur, d'où le protocole détaillé ci-dessus.

## C.2 — Tableau watch / read / select (au moins six points de lecture)

| Fichier / méthode | Donnée lue | Méthode retenue | Justification |
| --- | --- | --- | --- |
| `widgets/cart_badge.dart` / `build` | `RegistrationCart.totalPlacesReservees` | `context.select<RegistrationCart, int>` | Seul un entier dérivé intéresse ce badge ; `watch` reconstruirait le badge à chaque mutation du panier même quand le total ne change pas (ex. modification de session sans changement de quantité). |
| `widgets/event_tile.dart` / `EventTileSelectorCible.build` | `RegistrationCart.estDansLePanier(id)` | `context.select<RegistrationCart, bool>` | Démonstration C.1 : isole un booléen par identifiant pour ne reconstruire que les tuiles concernées par un ajout/retrait précis. |
| `widgets/event_tile.dart` / `EventTileConsumerLarge.build` | `RegistrationCart` entier | `context.watch<RegistrationCart>()` | Volontairement la configuration « large » à des fins de comparaison pédagogique en C.1 ; à éviter en dehors de cette démonstration. |
| `screens/event_list_screen.dart` / `_EventListScreenState.build` | `EventListNotifier.state` | `context.watch<EventListNotifier>()` | L'écran entier doit changer d'apparence (chargement/liste/erreur) : pas de sous-partie à isoler, un `select` n'apporterait rien ici. |
| `screens/event_list_screen.dart` / `_VueListe._trierEtFiltrer` | `DisplayPreferences` (tri ET filtre) | `context.watch<DisplayPreferences>()` | Les deux champs du notifier sont utilisés simultanément pour reconstruire la liste triée/filtrée ; un `select` unique ne suffirait pas sans en lire deux, ce qui n'apporterait pas de gain net ici. |
| `screens/event_list_screen.dart` / menu de tri (`onSelected`) | écriture sur `DisplayPreferences.changerTri` | `context.read<DisplayPreferences>()` | Mutation ponctuelle déclenchée par une interaction, sans besoin de s'abonner : `read` évite tout abonnement inutile pour un simple appel de méthode. |
| `screens/event_detail_screen.dart` / bouton « Ajouter au panier » | écriture sur `RegistrationCart.ajouter` | `context.read<RegistrationCart>()` | Mutation ponctuelle dans un gestionnaire d'événement ; utiliser `watch` ici abonnerait inutilement ce `build` (qui ne lit jamais le panier) à ses notifications. |
| `screens/event_detail_screen.dart` / `build` | `EventRepository` (dépôt en dur) | `context.read<EventRepository>()` | Le dépôt ne change jamais pendant l'exécution (`Provider` simple, pas de `ChangeNotifier`) : `watch` n'aurait aucun effet différent de `read` mais laisserait croire, à tort, que cette donnée peut varier. |
| `screens/cart_summary_screen.dart` / `build` | `RegistrationCart` entier (liste + total) | `context.watch<RegistrationCart>()` | Cet écran EST la vue du panier : toutes les données du notifier y sont affichées simultanément, un `Selector` n'isolerait rien de pertinent. |

## C.3 — Pourquoi l'injection par `ChangeNotifierProxyProvider` facilite l'évolution future

`RegistrationCart` et `EventListNotifier` ne connaissent de `EventRepository` que son
interface publique (`tousLesEvenements`, `parId`), reçue en paramètre de constructeur.
En séance 5, remplacer le dépôt en dur par une implémentation qui interroge une vraie
source de données revient à écrire une nouvelle classe respectant la même interface et à
changer une seule ligne dans `main.dart` (le `Provider<EventRepository>`) : aucun des deux
notifiers n'a besoin d'être modifié, testé à nouveau dans sa logique métier, ni même
recompilé au-delà de la résolution de types. C'est l'inversion de dépendance classique :
le notifier dépend d'une abstraction qu'on lui fournit, pas d'une implémentation
concrète qu'il choisirait lui-même.

## Frontière état local / état global — voir Partie D (esquisse)

La Partie D est volontairement une esquisse dans ce corrigé (voir `CORRIGE.md`, section
dédiée) : aucune implémentation de `ValueNotifier`/`ValueListenableBuilder` n'est fournie
ici, conformément à la consigne de couverture partielle du bonus.

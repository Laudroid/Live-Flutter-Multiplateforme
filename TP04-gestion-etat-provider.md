# TP 4 — Gestion d'état avec Provider : le panier d'inscriptions

| | |
| --- | --- |
| **Séance de référence** | Séance 4 — Gestion d'état avec Provider |
| **Durée** | 3h encadrées, finalisation en autonomie |
| **Modalité** | Individuel |
| **Prérequis** | Séances 1 à 3 : composition de widgets, `StatefulWidget`/`setState`, navigation (`Navigator`, routes) |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (ou version locale ; vérifier avec `flutter --version`), VSCode, `provider ^6.1.5` |

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- différencier état local (propre à un widget) et état global (partagé entre plusieurs écrans) et choisir le bon niveau pour chaque donnée ;
- constater par la pratique les limites de `setState` remonté par callbacks dans une application à plusieurs niveaux de widgets ;
- modéliser un état applicatif avec `ChangeNotifier`, l'exposer avec `ChangeNotifierProvider`/`MultiProvider` et le consommer avec `Consumer`, `Selector` ou `context.watch`/`read`/`select` ;
- choisir consciemment entre `watch`, `read` et `select` selon l'effet recherché sur la recomposition ;
- injecter une dépendance dans un notifier avec `ChangeNotifierProxyProvider` plutôt que de l'instancier en dur.

## Périmètre du TP

**Autorisé et attendu**

- `setState` (uniquement pour la démonstration du problème en Partie A, et pour de l'état strictement local ensuite)
- `ChangeNotifier`, `ChangeNotifierProvider`, `MultiProvider`, `Provider`, `Provider.value`
- `Consumer`, `Selector`, `context.watch`, `context.read`, `context.select`
- `ChangeNotifierProxyProvider`, `ProxyProvider` (injection de dépendances)
- `ValueNotifier`, `ValueListenableBuilder` (état local isolé, Partie D)
- `dispose()` sur les notifiers qui en définissent un
- Navigation du TP 3 (`Navigator`, routes nommées) en réemploi, nécessaire pour montrer l'état partagé entre écrans, mais **non évaluée** dans ce TP
- `Future.delayed` **uniquement** en Partie C, pour simuler une latence d'accès au dépôt de données et illustrer un état de chargement — aucun appel réseau réel

**Hors périmètre — l'usage sera pénalisé**

- Tout autre package de gestion d'état : Riverpod, Bloc/flutter_bloc, GetX, MobX
- `InheritedWidget` écrit à la main comme solution principale de partage d'état
- Tout appel réseau réel, `http`, ou logique `async` autre que le `Future.delayed` autorisé en Partie C (séance 5)
- `Form`, `TextFormField`, `TextEditingController` (séance 6)
- Toute persistance : `SharedPreferences`, fichiers, bases locales (séance 7)
- Firebase, quel que soit le module (séance 8)
- Animations, `MediaQuery`, `LayoutBuilder` (séance 9)
- Tests unitaires ou de widget (séance 10)

Les données proviennent d'un **dépôt en mémoire codé en dur** (une classe Dart exposant des listes constantes ou statiques). Aucune source externe.

## Mise en situation

Dans *Event Planner*, un participant construit son panier d'inscriptions en parcourant plusieurs écrans : la liste des événements, le détail d'un événement avec ses sessions, et un écran de synthèse du panier accessible depuis n'importe quel point de l'application via un badge dans l'`AppBar`. Jusqu'ici, votre navigation (TP 3) sait faire circuler des données *vers* un écran, mais rien ne permet à un écran de modifier un état et de voir cette modification reflétée instantanément sur un autre écran déjà affiché, ni sur l'`AppBar` commune. Remonter cet état à la main par callbacks à travers trois niveaux de widgets est le point de départ de ce TP ; vous allez constater ses limites, puis les dépasser avec Provider.

---

## Partie A — Prise en main guidée : du callback au premier `ChangeNotifier`

Objectif : reproduire le problème avant de le résoudre, et mesurer la différence.

### A.1 — Le compteur remonté par callbacks

1. Repartez d'un projet Flutter (`flutter create event_planner_state` ou réemploi d'un projet précédent avec navigation TP3).
2. Construisez trois niveaux de widgets imbriqués :
   - `EventListScreen` (niveau 1, `StatefulWidget`) détient un entier `_registrationCount` et une méthode `_increment()` gérés par `setState` ;
   - `EventListScreen` passe `_registrationCount` et `_increment` en paramètres à `EventSection` (niveau 2, `StatelessWidget`) ;
   - `EventSection` les repasse tels quels à `EventTile` (niveau 3, `StatelessWidget`), qui affiche le compteur et porte le bouton d'incrémentation.
3. Affichez également ce compteur dans une `AppBar` personnalisée construite dans un widget séparé `CartBadge`, lui aussi alimenté par paramètre depuis `EventListScreen`.
4. Ajoutez un `print` (ou un compteur incrémenté dans une variable statique) dans la méthode `build` de `EventTile`, `EventSection` et `CartBadge`. Appuyez cinq fois sur le bouton d'incrémentation et relevez dans un tableau, pour chacun des trois widgets, le nombre de fois où `build` a été appelé.
5. Naviguez vers un second écran factice puis revenez en arrière (`Navigator.pop`) : constatez et notez si le compteur a survécu ou non selon la façon dont vous avez construit la navigation.

**Critère de réussite observable** : vous disposez d'un tableau chiffré des recompositions et d'une observation écrite sur la survie de l'état à la navigation, tous deux consignés dans le `README.md`.

### A.2 — Constat

Rédigez dans le `README.md`, en une dizaine de lignes maximum, les trois limites concrètes que ce montage a révélées : (a) la plomberie de callbacks à travers des widgets qui n'utilisent pas eux-mêmes la donnée, (b) le volume de recompositions déclenchées par un seul incrément, (c) le lieu du TP où l'état vit et pourquoi cela le rend fragile à la navigation. Aucune notion de Partie B ou C n'est nécessaire à ce stade : ce constat s'appuie uniquement sur ce que vous venez d'observer.

### A.3 — Premier `ChangeNotifier`

1. Créez `lib/state/registration_cart.dart` avec une classe `RegistrationCart extends ChangeNotifier` exposant au minimum :
   ```dart
   class RegistrationCart extends ChangeNotifier {
     int get count => _count;
     int _count = 0;

     void increment() {
       _count++;
       notifyListeners();
     }
   }
   ```
2. Placez un unique `ChangeNotifierProvider<RegistrationCart>` au-dessus de `MaterialApp`, dans `main.dart`.
3. Remplacez la chaîne de callbacks : `EventTile` obtient désormais le compteur via un `Consumer<RegistrationCart>` (ou `context.watch`) placé au plus près de l'endroit où la valeur est réellement affichée, et déclenche `increment()` via `context.read<RegistrationCart>().increment()` dans le gestionnaire du bouton — jamais dans `build`.
4. `CartBadge` lit le même `RegistrationCart` indépendamment, sans qu'`EventListScreen` ait à lui transmettre quoi que ce soit par paramètre.
5. Reproduisez la mesure de recompositions de l'étape A.4 : relevez à nouveau le nombre d'appels à `build` de `EventTile`, `EventSection` et `CartBadge` pour cinq incréments, et comparez au tableau précédent dans le même document.
6. Reproduisez le test de navigation de l'étape A.5 : le compteur doit désormais survivre au `push`/`pop` puisqu'il vit au-dessus du `MaterialApp`.

**Critères de réussite observables** :
- `EventSection` ne reçoit plus ni le compteur ni le callback en paramètre ;
- le tableau de recompositions avant/après montre que `EventSection` n'est plus reconstruit du tout lors d'un incrément (il ne dépend plus de l'état) ;
- le compteur survit à un `push`/`pop` de navigation.

---

## Partie B — Mise en œuvre autonome : le panier complet et les préférences d'affichage

Objectif : un état de panier robuste et un état de préférences indépendant, tous deux exposés proprement. Aucune étape n'est détaillée : la spécification suffit.

### B.1 — Modèle de données en dur

Un dépôt en mémoire (par exemple `lib/data/event_repository.dart`) expose une liste fixe d'événements, chacun composé d'un identifiant, d'un titre, d'une catégorie, d'une capacité totale, d'un nombre de places déjà prises, et d'une liste de sessions (identifiant, libellé, horaire sous forme de chaîne). Aucune donnée n'est mutable dans ce dépôt : les mutations du panier sont un état séparé.

### B.2 — `RegistrationCart`, notifier de panier

Dans `lib/state/registration_cart.dart`, complétez (ou remplacez) le notifier de la Partie A pour qu'il gère une collection d'inscriptions (événement + session choisie + quantité de places réservées) avec les opérations suivantes, exposées publiquement :

- ajouter une inscription à un événement/session ;
- retirer une inscription ;
- modifier la quantité de places d'une inscription existante ;
- exposer un total de places réservées et un nombre d'événements distincts dans le panier.

Contraintes métier à faire respecter par le notifier lui-même, pas par les écrans :

- un même événement ne peut pas être ajouté deux fois au panier (une tentative d'ajout modifie l'inscription existante ou est refusée, à vous de documenter le choix retenu) ;
- l'ajout est refusé si l'événement est déjà complet (places prises + réservées dans le panier ≥ capacité) ;
- un plafond de places par utilisateur, toutes inscriptions confondues, ne peut pas être dépassé (valeur au choix, mais justifiée et documentée) ;
- toute opération refusée doit être signalée à l'appelant par une valeur de retour exploitable (booléen, résultat énuméré, ou exception dédiée) — pas seulement par un `print`.

**Contrainte de découplage stricte** : `lib/state/registration_cart.dart` ne doit importer **aucun** paquet `package:flutter/widgets.dart`, `package:flutter/material.dart` ni équivalent. Seuls `package:flutter/foundation.dart` (pour `ChangeNotifier`) et du Dart pur sont autorisés dans ce fichier. Un import interdit détecté dans ce fichier est éliminatoire pour ce sous-critère.

### B.3 — `DisplayPreferences`, second notifier indépendant

Créez `lib/state/display_preferences.dart` avec un `ChangeNotifier` distinct, sans aucune dépendance envers `RegistrationCart`, gérant :

- un critère de tri de la liste d'événements (au minimum deux valeurs : par titre, par date ou par places restantes) ;
- un filtre par catégorie (une catégorie choisie, ou aucune pour tout afficher) ;
- une densité d'affichage (au minimum deux valeurs, réemploi possible de la notion vue au TP 2).

Ce notifier respecte la même contrainte de découplage que `RegistrationCart`.

### B.4 — Assemblage par `MultiProvider`

Au-dessus de `MaterialApp`, assemblez les deux notifiers avec un unique `MultiProvider` :

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => RegistrationCart()),
    ChangeNotifierProvider(create: (_) => DisplayPreferences()),
  ],
  child: const EventPlannerApp(),
)
```

### B.5 — Badge de panier universel

Un `CartBadge` (ou équivalent) affiché dans l'`AppBar` de **tous** les écrans de navigation doit refléter le total de places réservées en temps réel, quel que soit l'écran où l'utilisateur modifie le panier. Vérifiez explicitement le scénario suivant et documentez le résultat dans le `README.md` : ajout d'une inscription depuis l'écran de détail d'un événement, retour à l'écran liste, le badge de l'écran liste doit déjà afficher la valeur à jour sans action supplémentaire.

**Contrainte de découplage stricte, côté widgets** : aucun widget de `lib/screens/` ou `lib/widgets/` ne doit muter directement un champ de `RegistrationCart` ou `DisplayPreferences` (pas d'accès à un setter public autre que les méthodes métier du notifier). Toute mutation transite par une méthode publique du notifier appelée via `context.read<...>()`.

**Critères de réussite observables** :
- les trois contraintes métier du panier sont démontrables individuellement (tentative d'ajout en double, tentative sur événement complet, dépassement de plafond) et chacune produit un signal exploitable, pas un plantage silencieux ;
- le badge se met à jour depuis n'importe quel écran sans callback manuel entre écrans ;
- `flutter analyze` ne signale aucun import Flutter dans les deux fichiers de `lib/state/`.

---

## Partie C — Approfondissement (niveau M2) : discipline de recomposition et injection de dépendances

Cette partie évalue votre capacité à justifier, chiffres à l'appui, les choix de gestion d'état d'une application non triviale.

### C.1 — Comptage instrumenté des recompositions

Instrumentez au moins deux widgets d'affichage de la liste d'événements (par exemple une tuile individuelle et le badge de panier) avec un compteur de recompositions visible à l'écran ou journalisé en console. Mesurez et consignez dans un tableau du `README.md` le nombre de `build` déclenchés par une même séquence d'actions (par exemple : trois ajouts au panier suivis d'un changement de tri) dans deux configurations :

- configuration « large » : la tuile consomme l'état entier du panier via `Consumer<RegistrationCart>` ou `context.watch<RegistrationCart>()` ;
- configuration « ciblée » : la même tuile consomme uniquement la donnée dont elle a besoin via `Selector<RegistrationCart, bool>` (par exemple, « cet événement est-il dans le panier ») ou `context.select`.

Le tableau comparatif avant/après est un livrable obligatoire de cette partie, avec les chiffres bruts, pas une estimation qualitative.

### C.2 — Choix justifié de `watch`/`read`/`select`

Pour chaque lecture de `RegistrationCart` ou de `DisplayPreferences` dans votre code, le choix entre `context.watch`, `context.read` et `context.select` (ou l'équivalent `Consumer`/`Selector`) doit être délibéré. Produisez dans le `README.md` un tableau recensant au moins six points de lecture dans votre code (fichier, ligne ou méthode, donnée lue) avec la méthode retenue et une justification d'une phrase par ligne. Un `context.watch` utilisé là où un `context.select` aurait suffi à isoler une valeur booléenne est un défaut à corriger, pas une variante acceptable.

### C.3 — Injection de dépendance par `ChangeNotifierProxyProvider`

Le dépôt d'événements (B.1) ne doit plus être instancié à l'intérieur du notifier. Injectez-le depuis l'extérieur avec `ChangeNotifierProxyProvider` :

```dart
ChangeNotifierProxyProvider<EventRepository, RegistrationCart>(
  create: (context) => RegistrationCart(repository: context.read<EventRepository>()),
  update: (context, repository, previousCart) =>
      previousCart!..updateRepository(repository),
)
```
(Signature à adapter à votre conception ; ne recopiez pas cet exemple tel quel, il illustre uniquement le mécanisme attendu.)

`EventRepository` lui-même est fourni par un `Provider<EventRepository>` simple, placé au-dessus dans le même `MultiProvider`. Expliquez en cinq lignes dans le `README.md` pourquoi cette indirection facilite le remplacement futur du dépôt en dur par une source réelle (séance 5), sans modifier `RegistrationCart`.

### C.4 — État de chargement et d'erreur par machine à états scellée

Simulez un temps d'accès au dépôt avec `Future.delayed` (200 à 800 ms) lors du chargement initial de la liste d'événements, et un cas d'échec simulé (déclenché par un paramètre ou un bouton de test, pas par une vraie panne réseau). Représentez les trois états — chargement, succès avec données, erreur — par une machine à états scellée : un `sealed class EventListState` avec des sous-classes (`EventListLoading`, `EventListLoaded`, `EventListError`), ou un `enum` de statut associé à des champs cohérents entre eux. L'usage de deux ou trois booléens indépendants (`isLoading`, `hasError`, etc.) pour représenter ces trois états est un défaut à corriger : rien n'empêche alors un état incohérent comme `isLoading == true && hasError == true` en même temps.

Contraintes supplémentaires :
- `notifyListeners()` ne doit jamais être appelé pendant la phase de construction d'un widget (pas d'appel direct dans `build` ni dans un `initState` sans passer par `addPostFrameCallback` ou un chargement différé) ;
- tout notifier possédant des ressources à libérer (minuteur, écouteur externe) redéfinit `dispose()` et appelle `super.dispose()` ;
- l'écran affiche un indicateur de chargement, la liste, ou un message d'erreur avec action de nouvelle tentative, selon l'état courant, par un `switch` exhaustif sur la machine à états (pas de `if/else` en cascade non exhaustif).

**Critères de réussite observables** : le tableau comparatif de C.1 est présent avec des chiffres ; la machine à états ne permet pas de représenter un état incohérent (vérifiable en lisant le type) ; `flutter analyze` ne signale aucun avertissement de `notifyListeners` appelé de façon inappropriée ; le dépôt est injecté, jamais instancié dans le constructeur du notifier.

---

## Partie D — Défi optionnel : frontière entre état local et état global

1. Choisissez une portion de l'interface qui n'a aucune raison de dépendre du panier ou des préférences globales (par exemple : l'état ouvert/fermé d'un panneau d'aide, la page courante d'un carrousel purement visuel, l'état de survol ou d'expansion d'une carte). Implémentez cet état avec un `ValueNotifier` local au widget et un `ValueListenableBuilder` ciblé, sans jamais remonter cette donnée dans `RegistrationCart`, `DisplayPreferences`, ni aucun `Provider`.
2. Rédigez une note argumentée d'une demi-page (25 à 35 lignes) dans le `README.md`, intitulée « Frontière état local / état global », qui :
   - définit le critère que vous retenez pour trancher (portée, durée de vie, nombre de widgets consommateurs, nécessité de survivre à la navigation, ou tout autre critère explicite et défendable) ;
   - classe et justifie **trois exemples concrets de votre application** : un exemple d'état clairement local, un exemple d'état clairement global, et un exemple limite où le choix méritait discussion, en expliquant pourquoi vous avez tranché dans un sens plutôt que l'autre.

**Critère de réussite observable** : le `ValueNotifier` introduit en D.1 n'apparaît dans aucun `Provider` et aucun widget extérieur à la portion concernée n'y accède.

---

## Critères d'évaluation

Noté sur 20, bonus plafonné à 2 points.

| Critère | Points |
| --- | --- |
| **Partie A — du callback au premier `ChangeNotifier`** | **5** |
| Montage à trois niveaux par callbacks fonctionnel, tableau de recompositions initial correct | 1,5 |
| Constat écrit des trois limites (plomberie, recompositions, survie à la navigation) | 1 |
| `RegistrationCart` introduit, `ChangeNotifierProvider` au-dessus du `MaterialApp` | 1 |
| Tableau de recompositions après migration montrant la réduction, et survie à la navigation démontrée | 1,5 |
| **Partie B — panier complet et préférences** | **6** |
| Les trois contraintes métier du panier sont implémentées et démontrables individuellement | 2 |
| `DisplayPreferences` indépendant, assemblage par `MultiProvider` | 1 |
| Badge de panier universel, mise à jour vérifiée depuis un autre écran | 1,5 |
| Découplage strict : aucun import Flutter dans `lib/state/`, aucune mutation directe depuis un widget | 1,5 |
| **Partie C — recomposition et injection de dépendances** | **5** |
| Tableau comparatif chiffré Consumer entier vs `Selector`/`context.select` | 1,5 |
| Tableau de justification `watch`/`read`/`select` sur au moins six points de lecture | 1 |
| Dépôt injecté par `ChangeNotifierProxyProvider`, jamais instancié dans le notifier | 1 |
| Machine à états scellée pour chargement/succès/erreur, `dispose()` correct, pas de `notifyListeners` en construction | 1,5 |
| **Qualité du code** | **2** |
| `flutter analyze` sans avertissement, découpage cohérent, nommage cohérent | 2 |
| **`USAGE-IA.md`** | **2** |
| Complétude, sincérité, esprit critique sur les réponses obtenues | 2 |
| **Partie D — frontière local/global (bonus)** | **+2** |

Pénalités : usage d'une notion hors périmètre (Riverpod, Bloc, GetX, MobX, `InheritedWidget` manuel comme solution principale, appel réseau réel, `Form`, persistance, Firebase, animations, `MediaQuery`/`LayoutBuilder`, tests) : **−2 points par notion**. Absence de `USAGE-IA.md` : rendu déclaré incomplet.

---

## Livrables

Archive `TP04-NOM-Prenom.zip` ou dépôt git, contenant :

```
event_planner_state/
├── lib/
│   ├── main.dart
│   ├── data/
│   │   └── event_repository.dart
│   ├── models/
│   │   ├── event.dart
│   │   ├── session.dart
│   │   └── registration.dart
│   ├── state/
│   │   ├── registration_cart.dart
│   │   ├── display_preferences.dart
│   │   └── event_list_state.dart
│   ├── widgets/
│   │   ├── cart_badge.dart
│   │   ├── event_tile.dart
│   │   └── event_section.dart
│   └── screens/
│       ├── event_list_screen.dart
│       ├── event_detail_screen.dart
│       └── cart_summary_screen.dart
├── pubspec.yaml
├── README.md
├── USAGE-IA.md
└── captures/                  # captures des tableaux de recomposition et du badge à jour
```

Extrait attendu du `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5

dev_dependencies:
  flutter_lints: ^6.0.0
```

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA — TP 4 — <Nom Prénom>

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

- Introduction à la gestion d'état dans Flutter : https://docs.flutter.dev/data-and-backend/state-mgmt/intro
- Approches simples de gestion d'état (`setState`, remontée d'état) : https://docs.flutter.dev/data-and-backend/state-mgmt/simple
- Package `provider` sur pub.dev : https://pub.dev/packages/provider
- `ChangeNotifier` (API de référence) : https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
- `ValueListenableBuilder` (API de référence) : https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html
- Options de gestion d'état, vue d'ensemble : https://docs.flutter.dev/data-and-backend/state-mgmt/options
- DevTools, onglet Performance pour observer les recompositions : https://docs.flutter.dev/tools/devtools/performance

Les signatures évoluent d'une version de Flutter à l'autre : vérifiez systématiquement sur `api.flutter.dev` que l'API que vous employez existe dans la version retournée par `flutter --version`.

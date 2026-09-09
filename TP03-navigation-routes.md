# TP 3 — Navigation et routes : le mur d'événements devient navigable

| | |
| --- | --- |
| **Séance de référence** | Séance 3 — Navigation et routes |
| **Modalité** | Individuel |
| **Prérequis** | TP 2 validé : `Event`, jeu de données, `EventCard`, écran d'accueil composé sans débordement |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (ou version locale ; vérifier avec `flutter --version`), VSCode |

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- implémenter une navigation impérative multi-écrans avec `Navigator.push` et `Navigator.pop` ;
- transférer des données entre deux vues, dans un sens (arguments) puis dans les deux sens (valeur de retour) ;
- structurer une table de routes nommées dans un fichier centralisé, avec des constantes typées ;
- extraire et valider des arguments de route reçus via `RouteSettings`, y compris dans les cas d'erreur ;
- choisir la primitive de navigation adaptée à une intention (empiler, remplacer, revenir à la racine, intercepter le retour).

## Périmètre du TP

**Autorisé et attendu**

- `Navigator.push`, `.pop`, `.pushNamed`, `.pushReplacement`, `.pushReplacementNamed`, `.pushAndRemoveUntil`, `.popUntil`
- `MaterialPageRoute`, `PageRouteBuilder` pour une transition simple (fondu ou glissement, sans dépendance externe)
- Routes nommées : table `routes:` du `MaterialApp`, `onGenerateRoute`, `onUnknownRoute`
- `RouteSettings` et `arguments`, valeur de retour de `pop` (le `Future<T?>` renvoyé par `push`/`pushNamed`)
- `WillPopScope` ou, préférentiellement sur votre version de SDK, `PopScope` pour intercepter le retour matériel
- `showDialog`, `showModalBottomSheet` (ce sont des routes au sens du `Navigator`)
- `Navigator` imbriqué (Partie D)
- `BottomNavigationBar` ou `TabBar` en tant que structure d'écran (Partie D)
- Réutilisation intégrale du modèle `Event` et du jeu de données du TP 2, `EventCard` inchangée dans son contrat visuel

**Hors périmètre — l'usage sera pénalisé**

- `go_router` ou toute dépendance de routage externe ajoutée au `pubspec.yaml`
- Navigator 2.0 déclaratif : `Router`, `RouterDelegate`, `RouteInformationParser`, `Page`
- Tout état global : `provider`, `ChangeNotifier`, `InheritedWidget` (séance 4) — une donnée qui doit voyager d'un écran à l'autre transite exclusivement par les arguments de route à l'aller, et par la valeur de retour de `pop` au retour
- Tout appel réseau, `http`, `FutureBuilder` branché sur une source distante (séance 5)
- `Form`, `TextFormField`, `TextEditingController` : pour saisir une donnée (choisir une session, un tarif, confirmer un choix), utilisez un dialogue à choix multiples ou des boutons, jamais un champ de texte libre
- Toute persistance (séance 7), tout Firebase (séance 8)
- Widgets animés `AnimatedXxx`, `Hero`, `MediaQuery`, `LayoutBuilder` (séance 9)

Les données restent **codées en dur**, reprises du TP 2. Aucune identité d'événement ne doit être recalculée : vous devez pouvoir désigner un événement par un identifiant stable (ajoutez un champ `id` au modèle `Event` si votre TP 2 ne l'avait pas).

## Mise en situation

Le mur d'événements du TP 2 est visuellement complet mais mort au toucher : aucune carte ne mène nulle part. L'équipe produit demande un parcours utilisateur complet pour *Event Planner* : consulter le détail d'un événement, choisir une formule de participation, confirmer, puis revenir à l'accueil sans que le bouton retour du téléphone ne ramène sur un écran de confirmation obsolète. Ce TP ne touche à aucune logique de persistance ni de compte utilisateur : il s'agit uniquement de faire circuler l'information entre des écrans, dans l'ordre, avec les bons outils de navigation.

---

## Partie A — Prise en main guidée : du `push` direct aux routes nommées

Objectif : mettre en place le trajet minimal accueil → détail → retour, d'abord de la façon la plus directe possible, puis en le faisant migrer vers une table de routes centralisée.

### A.1 — Navigation impérative directe

1. Reprenez le projet du TP 2 (ou repartez de `flutter create event_planner_nav` en réimportant `models/event.dart`, `data/sample_events.dart`, `widgets/event_card.dart`).
2. Créez `lib/screens/event_detail_screen.dart` contenant un `StatelessWidget` de signature :
   ```dart
   class EventDetailScreen extends StatelessWidget {
     const EventDetailScreen({super.key, required this.event});
     final Event event;
     // ...
   }
   ```
   Cet écran affiche au minimum : le titre, la ville et le lieu, la date formatée, la catégorie, la jauge de places (widget réutilisé du TP 2) et un bouton « Retour ».
3. Rendez chaque `EventCard` du mur d'événements cliquable (`InkWell` ou `GestureDetector`) : au tap, appelez `Navigator.push` avec un `MaterialPageRoute` construisant `EventDetailScreen(event: ...)`, en passant l'objet `Event` complet en argument de constructeur.
4. Le bouton « Retour » de l'écran de détail appelle `Navigator.pop(context)`. Vérifiez que la flèche de retour automatique de l'`AppBar` fonctionne également sans code supplémentaire — expliquez en une phrase dans le `README.md` pourquoi elle apparaît sans que vous l'ayez programmée.
5. Vérifiez que l'objet reçu sur l'écran de détail est bien celui qui a été tapé (testez avec au moins trois événements différents du jeu de données) et qu'aucune donnée n'est recalculée ou récupérée par un autre canal que le constructeur.

**Critère de réussite observable** : depuis n'importe quelle carte du mur, le détail affiché correspond exactement à l'événement tapé, et le retour matériel comme le retour applicatif ramènent sur le mur sans reconstruire l'écran d'accueil depuis zéro (pas de perte de position de défilement au retour).

### A.2 — Migration vers des routes nommées

1. Créez `lib/routes/app_routes.dart` avec une classe (ou un ensemble de constantes) exposant les noms de route sous forme de constantes `String` typées, par exemple :
   ```dart
   abstract final class AppRoutes {
     static const String home = '/';
     static const String eventDetail = '/event-detail';
     // à compléter en Partie B et C
   }
   ```
   Aucune chaîne littérale de route ne doit apparaître ailleurs que dans ce fichier : tout appel à `pushNamed` référence une constante `AppRoutes.xxx`.
2. Déclarez la table `routes:` dans le `MaterialApp` pour `AppRoutes.home`. Pour `AppRoutes.eventDetail`, qui a besoin de recevoir un argument dynamique (l'événement tapé), expliquez dans le `README.md` pourquoi la table `routes:` seule est insuffisante et quelle alternative vous employez (indice : `onGenerateRoute`, approfondi en Partie C ; à ce stade, une construction via `settings.arguments` dans une fonction de route dédiée suffit).
3. Remplacez l'appel `Navigator.push(MaterialPageRoute(...))` de la question A.1.3 par `Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: event)`.
4. Sur l'écran de détail, récupérez l'argument via `ModalRoute.of(context)!.settings.arguments`, castez-le vers `Event`, et conservez le même rendu qu'en A.1.

**Critère de réussite observable** : aucune chaîne de route littérale hors de `app_routes.dart` ; le comportement observé par l'utilisateur est identique à celui de A.1 ; le cast de l'argument est explicite et localisé.

---

## Partie B — Mise en œuvre autonome : le parcours de réservation complet

Objectif : construire un parcours à quatre écrans faisant circuler une valeur dans les deux sens. Aucune étape n'est détaillée pas à pas : la spécification fonctionnelle suffit.

Le parcours attendu :

1. **Accueil** (mur d'événements, issu de la Partie A) : point d'entrée et point de retour final.
2. **Détail d'un événement** : accessible par route nommée avec passage de l'`Event` (ou de son identifiant, à votre choix à ce stade — la Partie C imposera l'identifiant). Propose un bouton « Choisir une formule ».
3. **Écran de sélection** : présente au moins trois formules de participation codées en dur (par exemple « Standard », « Essentiel », « VIP », chacune avec un tarif et une description courte). L'utilisateur choisit une formule par un bouton ou une carte cliquable — aucun champ de texte. Cet écran ne pousse pas un nouvel écran : il **renvoie sa sélection** à l'écran de détail via `Navigator.pop(context, formuleChoisie)`. L'écran de détail attend ce retour avec un `Future` correctement typé (pas de `dynamic` non justifié) et doit gérer explicitement le cas où l'utilisateur revient en arrière sans choisir (le bouton retour matériel ou une flèche d'`AppBar`), auquel cas la valeur reçue est `null`.
4. **Écran de confirmation** : atteint uniquement lorsqu'une formule a été choisie (valeur non nulle reçue à l'étape précédente), via `Navigator.pushReplacement`. Affiche un récapitulatif (événement, formule, tarif). Le choix de `pushReplacement` plutôt que `push` est délibéré : vérifiez et documentez dans le `README.md` que le bouton retour matériel, depuis l'écran de confirmation, ne ramène **pas** sur l'écran de sélection ni de détail, mais directement sur l'écran qui précédait l'écran remplacé.
5. **Retour à l'accueil** : un bouton « Retour à l'accueil » sur l'écran de confirmation ramène directement au mur d'événements, en vidant toute la pile intermédiaire. Utilisez `Navigator.popUntil` ou `Navigator.pushAndRemoveUntil` — justifiez votre choix entre les deux en une phrase dans le `README.md`.

Contraintes de robustesse :

- si l'utilisateur annule à l'étape 3, l'écran de détail doit rester utilisable normalement (pas d'écran blanc, pas d'exception, pas de récapitulatif partiel affiché) ;
- le type du `Future` retourné par l'appel de navigation vers l'écran de sélection doit apparaître explicitement dans votre code (par exemple `Future<Formule?>`), sans recours à `dynamic` ;
- aucune de ces données (événement choisi, formule choisie) ne doit transiter par une variable globale, un singleton ou un champ statique : uniquement par arguments de route et valeurs de retour.

**Critère de réussite observable** : le parcours complet (accueil → détail → sélection → annulation → détail → sélection → confirmation → accueil) fonctionne sans exception ; à aucun moment le bouton retour matériel ne ramène sur un écran incohérent avec l'état du parcours.

---

## Partie C — Approfondissement : contrat d'interface d'une route

Cette partie évalue votre capacité à traiter une route comme une interface publique, avec ses cas d'erreur.

1. **Passage par identifiant, pas par objet.** Modifiez la route de détail d'événement pour qu'elle reçoive désormais un `String id` (ou l'équivalent typé de votre modèle) plutôt que l'objet `Event` complet. La résolution de l'identifiant vers l'objet complet doit se faire à l'intérieur de l'écran de détail ou de la fonction de génération de route, à partir du jeu de données du TP 2.

2. **`onGenerateRoute` avec validation.** Remplacez ou complétez la table `routes:` par un `onGenerateRoute` centralisé dans `lib/routes/app_routes.dart` (ou un fichier dédié `lib/routes/route_generator.dart` référencé depuis `app_routes.dart`). Cette fonction doit gérer explicitement, pour la route de détail, trois cas :
   - **arguments absents** (`settings.arguments == null`) ;
   - **arguments d'un type inattendu** (par exemple une `String` alors qu'un `Map` est attendu, ou l'inverse) ;
   - **identifiant syntaxiquement valide mais inexistant** dans le jeu de données.

   Chacun de ces trois cas doit conduire à un écran d'erreur explicite et lisible par l'utilisateur (pas une exception non interceptée, pas un écran blanc), distinct de l'écran 404 de la question suivante ou fusionné avec lui — à vous de justifier votre choix dans le `README.md`.

3. **Route inconnue.** Fournissez un `onUnknownRoute` renvoyant un écran 404 générique, utilisable pour n'importe quel nom de route non enregistré, proposant un bouton de retour à l'accueil via `pushAndRemoveUntil`.

4. **Interception du retour en cours de parcours.** Sur l'écran de sélection de formule (Partie B), ajoutez un `PopScope` (ou `WillPopScope` si votre version de SDK ne propose pas encore `PopScope` — vérifiez sur `api.flutter.dev`) qui intercepte toute tentative de retour, matérielle ou applicative, et affiche un dialogue de confirmation (« Abandonner la sélection en cours ? ») avant de laisser la navigation se poursuivre. L'annulation du dialogue ne doit produire aucune navigation.

5. **Table de routes documentée.** Produisez dans le `README.md` un tableau Markdown recensant toutes les routes de l'application, avec au minimum les colonnes suivantes :

   | Nom de route | Constante | Arguments attendus | Type de retour |
   | --- | --- | --- | --- |
   | *(exemple, à compléter pour vos routes réelles)* | `AppRoutes.eventDetail` | `String id` | aucun (`void`) |

6. **Réflexion écrite.** Rédigez dans le `README.md` un paragraphe d'au moins dix lignes répondant à : pourquoi préférer un identifiant à un objet complet dans les arguments d'une route ; ce que ce choix implique pour un lien profond (*deep link*) qui ouvrirait directement l'écran de détail sans passer par l'accueil ; ce qu'il implique pour la restauration d'état après redémarrage de l'application (même si cette restauration n'est pas implémentée dans ce TP — c'est une réflexion, pas un livrable de code).

**Critères de réussite observables** : les trois cas d'erreur d'argument produisent chacun un affichage distinct de l'exception brute ; une route inexistante quelconque atterrit sur le même écran 404 ; le dialogue d'abandon bloque effectivement la navigation tant qu'il n'est pas validé ; le tableau de routes est exhaustif (aucune route du code absente du tableau).

---

## Partie D — Défi optionnel : navigateurs imbriqués par onglet

Ajoutez une structure à onglets (`BottomNavigationBar` ou `TabBar`, à votre choix) avec au moins deux onglets, par exemple « Accueil » et « Mes réservations ». Chaque onglet possède son propre `Navigator` imbriqué avec sa propre pile : naviguer vers un détail depuis l'onglet « Accueil » n'affecte pas la pile de l'onglet « Mes réservations », et réciproquement.

Contrainte comportementale à démontrer : lorsqu'un onglet a une pile de navigation profonde (par exemple accueil → détail → sélection) et que l'utilisateur actionne le retour matériel, la première pression dépile l'écran courant de l'onglet actif ; ce n'est que lorsque la pile de l'onglet actif est réduite à sa racine qu'une pression supplémentaire peut faire sortir de l'application (ou, à votre choix documenté, ramener au premier onglet). Changer d'onglet ne doit jamais réinitialiser la pile de l'onglet quitté : revenir sur un onglet où l'on avait navigué en profondeur doit le retrouver dans l'état où on l'a laissé.

Aucun `Hero`, aucune dépendance externe de gestion d'onglets : uniquement les widgets du périmètre autorisé.

---

## Livrables

Archive `TP03-NOM-Prenom.zip` ou dépôt git, contenant :

```
event_planner_nav/
├── lib/
│   ├── main.dart
│   ├── data/sample_events.dart
│   ├── models/event.dart
│   ├── routes/
│   │   ├── app_routes.dart
│   │   └── route_generator.dart
│   ├── widgets/event_card.dart
│   └── screens/
│       ├── event_wall_screen.dart
│       ├── event_detail_screen.dart
│       ├── package_selection_screen.dart
│       ├── confirmation_screen.dart
│       └── not_found_screen.dart
├── pubspec.yaml
├── README.md
├── USAGE-IA.md
└── captures/                  # captures de chaque écran du parcours, dans l'ordre
```

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA — TP 3 — <Nom Prénom>

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

---

## Ressources

- Navigation de base, notion de pile : https://docs.flutter.dev/ui/navigation
- Cookbook — naviguer vers un nouvel écran et revenir : https://docs.flutter.dev/cookbook/navigation/navigation-basics
- Cookbook — retourner des données depuis un écran : https://docs.flutter.dev/cookbook/navigation/returning-data
- Cookbook — passer des arguments à une route nommée : https://docs.flutter.dev/cookbook/navigation/navigate-with-arguments
- Classe `Navigator` (API complète, `push`/`pop`/`pushAndRemoveUntil`/`popUntil`) : https://api.flutter.dev/flutter/widgets/Navigator-class.html
- Classe `RouteSettings` : https://api.flutter.dev/flutter/widgets/RouteSettings-class.html
- Classe `PopScope` : https://api.flutter.dev/flutter/widgets/PopScope-class.html


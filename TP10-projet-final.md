# TP 10 — Projet final : Event Planner App

| | |
| --- | --- |
| **Séance de référence** | Séance 10 — Projet final : intégration, tests, publication |
| **Durée** | 3h en autonomie |
| **Modalité** | Individuel |
| **Prérequis** | Séances 1 à 9 intégralement : composition de widgets, navigation à routes nommées, `Provider`, consommation d'API REST, formulaires validés, persistance locale, Firebase Auth et Firestore, mise en page adaptative et animations implicites |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (ou version locale ; vérifier avec `flutter --version`), VSCode |

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- intégrer dans un seul projet cohérent l'ensemble des compétences acquises depuis la séance 2, sans les traiter comme des îlots juxtaposés ;
- concevoir une architecture en couches qui rend cette intégration soutenable, avec une règle de dépendance explicite et vérifiable ;
- finaliser une application réellement utilisable de bout en bout, y compris sur ses chemins d'erreur et d'absence de connexion ;
- écrire des tests automatisés ciblés sur la logique métier, les widgets critiques et les cas d'échec réseau, exécutables sans dépendance réelle à un réseau ou à Firebase ;
- nettoyer un code de taille réelle, produire un artefact de publication en mode release, et conduire une revue de code — humaine et assistée par IA — argumentée.

## Compétences obligatoirement mobilisées

Ce TP est le seul de la formation qui n'a pas d'encadré de périmètre restreint. Il en a l'inverse : chacune des huit compétences suivantes doit être identifiable dans le code rendu, et vous devez la localiser vous-même dans le tableau de traçabilité de votre `README.md` (voir section Livrables). Une compétence non mobilisée ou non traçable est pénalisée indépendamment du reste de la notation.

| # | Séance | Compétence obligatoire |
| --- | --- | --- |
| 1 | Séance 2 | Composition et widgets réutilisables, sans débordement sur aucun écran |
| 2 | Séance 3 | Navigation à routes nommées centralisées, avec passage d'arguments et valeurs de retour |
| 3 | Séance 4 | État partagé par `Provider`, avec séparation stricte de l'état et de l'interface |
| 4 | Séance 5 | Consommation d'une API REST avec modèles typés, gestion des états de chargement et d'erreur |
| 5 | Séance 6 | Au moins un formulaire à validation croisée |
| 6 | Séance 7 | Préférences persistantes et données locales sur disque |
| 7 | Séance 8 | Authentification Firebase et une collection Firestore protégée par des règles de sécurité |
| 8 | Séance 9 | Mise en page adaptative, animations implicites et accessibilité |

Aucune notion des séances 1 à 9 n'est hors périmètre ici. À l'inverse, une fonctionnalité qui n'appartient à aucune de ces séances (par exemple un moteur de paiement, une carte interactive, ou toute dépendance non listée dans l'environnement de référence) reste hors sujet.

## Mise en situation

Le fil rouge de la formation, *Event Planner*, arrive à son terme. Vous livrez la version candidate à la publication : un catalogue d'événements alimenté par une API distante, un espace organisateur authentifié pour créer et gérer ses propres événements, une inscription de participant soumise à des règles métier, et une expérience qui reste utilisable en préférences locales et en connexion instable. Le produit doit être démontrable en dix minutes devant un tiers qui n'a pas suivi son développement, et défendable ligne par ligne : toute portion de code que vous ne savez pas expliquer en soutenance est sanctionnée, qu'elle fonctionne ou non.

---

## Portée fonctionnelle de l'application

### Attendu minimal

1. **Catalogue d'événements** alimenté par `https://dummyjson.com` (endpoint au choix, adapté au domaine événementiel — par exemple `products` ou `posts` réinterprétés comme événements, ou toute ressource dont la forme convient), avec :
   - pagination par `limit` et `skip`, exploitant le champ `total` de la réponse pour savoir quand arrêter de charger ;
   - recherche par texte, avec gestion du cas « aucun résultat » distincte du cas « erreur » ;
   - gestion visible de la latence (`?delay=`) et de l'échec (`/http/500`) : aucun de ces deux cas ne doit produire un écran figé ou un plantage.
2. **Espace organisateur authentifié** (Firebase Auth) permettant de créer, modifier et supprimer *ses propres* événements, stockés dans Firestore. Un organisateur ne doit ni voir ni pouvoir modifier les événements d'un autre compte depuis l'interface, et cette restriction doit être également imposée côté règles de sécurité Firestore, pas seulement côté interface.
3. **Inscription d'un participant** à un événement, avec deux contraintes métier non négociables :
   - refus de l'inscription si l'événement a atteint sa capacité ;
   - refus d'une deuxième inscription de la même personne au même événement (doublon).
4. **Liste des inscriptions en cours**, gérée par un `ChangeNotifier` exposé via `Provider`, consultable et modifiable (retrait d'une inscription) avant confirmation finale.
5. **Préférences utilisateur persistantes** : au minimum le thème (clair/sombre/système) et un critère de tri ou de filtre par défaut du catalogue, conservés entre deux lancements via `SharedPreferencesAsync` ou `SharedPreferencesWithCache`.
6. **Mode dégradé hors connexion** : au minimum, le dernier catalogue chargé avec succès reste consultable en lecture lorsque l'appel réseau échoue, avec un signal visuel explicite indiquant que les données affichées ne sont pas fraîches.
7. **Interface adaptative et accessible** : la mise en page se réorganise entre un téléphone étroit et une largeur de tablette, sans recourir à un simple redimensionnement proportionnel ; les zones interactives respectent une taille minimale d'atteinte tactile et les images porteuses de sens ont un équivalent textuel.

### Optionnel (ne relève pas de la Partie B, voir Partie D)

- Synchronisation différée des actions effectuées hors connexion.
- Notifications locales de rappel avant un événement.
- Partage d'un événement vers une application tierce.
- Statistiques d'un organisateur sur ses propres événements.

Tout optionnel non demandé explicitement en Partie D n'apporte aucun point : il consomme du temps qui doit aller à l'attendu minimal et aux tests.

---

## Partie A — Mise sur les rails

Objectif : poser une architecture en couches capable de porter l'ensemble du projet, puis prouver qu'elle fonctionne de bout en bout avant tout développement en largeur.

1. **Arborescence imposée**, quatre couches, avec une règle de dépendance à sens unique vers le domaine :

   ```
   lib/
   ├── presentation/   (écrans, widgets, thème, routes)
   ├── state/          (ChangeNotifier, providers d'état)
   ├── domain/         (modèles immuables, interfaces de dépôt, règles métier pures)
   └── data/           (implémentations de dépôt, clients HTTP, Firestore, stockage local)
   ```

   Règle de dépendance : `presentation` peut dépendre de `state` et `domain` ; `state` peut dépendre de `domain` ; `data` implémente les interfaces de `domain` mais `domain` ne connaît jamais `data`, `presentation` ni Flutter lui-même pour sa logique pure. **Un import d'un widget (`package:flutter/material.dart` ou tout fichier de `presentation/`) depuis un fichier de `data/` est une violation d'architecture explicitement interdite**, quel que soit son motif.

2. **Fichiers de configuration** à produire avant tout écran :
   - `analysis_options.yaml` durci, activant `flutter_lints` et au moins cinq règles additionnelles explicites (par exemple `prefer_const_constructors`, `avoid_print`, `unawaited_futures`) ;
   - `lib/presentation/routes.dart` : table de routes nommées centralisée, unique point d'enregistrement ;
   - `lib/presentation/theme/app_theme.dart` : thème unique, clair et sombre, aucune couleur codée en dur ailleurs ;
   - `lib/main.dart` : point d'entrée garantissant, avant le premier appel à `runApp`, l'initialisation de Firebase (`Firebase.initializeApp`) et le chargement des préférences nécessaires au premier rendu (thème notamment). Squelette attendu :
     ```dart
     Future<void> main() async {
       WidgetsFlutterBinding.ensureInitialized();
       await Firebase.initializeApp(/* ... */);
       final prefs = await AppPreferences.load(/* ... */);
       runApp(EventPlannerApp(initialPrefs: prefs));
     }
     ```

3. **Modèles de domaine immuables**, égalité de valeur explicite (constructeur `const`, `==` et `hashCode` surchargés ou `Equatable`, pas de mutation après construction). Au minimum `Event`, `Registration`, `UserProfile`.

4. **Interfaces de dépôt côté domaine, implémentations côté données.** Exemple de signature à respecter, sans en livrer le corps :
   ```dart
   // domain/repositories/event_repository.dart
   abstract class EventRepository {
     Future<EventPage> fetchEvents({required int limit, required int skip, String? query});
     Future<Event> fetchEventById(String id);
   }
   ```
   ```dart
   // data/repositories/remote_event_repository.dart
   class RemoteEventRepository implements EventRepository {
     RemoteEventRepository({required http.Client client});
     // ...
   }
   ```

5. **Jalon obligatoire : un parcours vertical de bout en bout.** Avant tout développement en largeur (avant d'ajouter un deuxième écran, une deuxième source de données ou une deuxième fonctionnalité), l'application doit afficher, depuis un unique écran, une unique liste d'événements provenant réellement de l'API distante, en traversant réellement les quatre couches — aussi mince que ce parcours puisse être : pas de filtre, pas de pagination, pas d'authentification à ce stade. Ce jalon doit correspondre à **un commit identifiable** (message de commit explicite, par exemple `feat: parcours vertical minimal catalogue -> API`), retrouvable dans l'historique remis. Un projet sans ce commit isolable est considéré comme n'ayant pas respecté la progression demandée, même si le produit final fonctionne.

**Critères de réussite observables** : l'arborescence en couches existe dès le premier commit de code fonctionnel ; aucun fichier de `data/` n'importe un widget ; le jalon du parcours vertical est identifiable dans l'historique de version ; `flutter run` affiche une liste réelle issue de l'API dès ce jalon.

---

## Partie B — Mise en œuvre autonome : le produit

Objectif : réaliser l'ensemble de la portée fonctionnelle minimale décrite plus haut, en développant désormais en largeur sur les fondations posées en Partie A. Aucune étape n'est détaillée : la spécification fonctionnelle et les exigences transverses suffisent.

Exigences transverses, valables sur **chaque écran** de l'application :

- gestion explicite et visuellement distincte des quatre états suivants, chacun avec un rendu propre (pas de simple texte brut en cas d'erreur) : absence de données (liste vide légitime), chargement en cours, erreur (réseau, serveur, ou règle métier refusée), session expirée ou utilisateur non connecté sur un écran qui requiert une identité ;
- aucun plantage sur un chemin d'erreur : forcer `/http/500`, couper le réseau, ou invalider une session ne doit jamais produire un écran rouge ou une fermeture de l'application ;
- comportement cohérent lorsque l'utilisateur n'est pas connecté : les écrans de consultation (catalogue) restent accessibles, les actions qui requièrent une identité (créer un événement, s'inscrire) proposent explicitement l'authentification plutôt que d'échouer silencieusement ou de planter.

Fonctionnalités à livrer : voir la section « Attendu minimal » ci-dessus. Elle fait foi.

**Critères de réussite observables** : les quatre contraintes de capacité, doublon, pagination et mode dégradé sont vérifiables manuellement avec un scénario reproductible que vous décrivez dans le `README.md` ; aucun écran ne plante lors d'une coupure réseau simulée ; un utilisateur non connecté peut consulter le catalogue et se voit proposer une connexion au bon moment, jamais un échec muet.

---

## Partie C — Approfondissement : qualité, tests, industrialisation

Cette partie évalue votre capacité d'ingénieur à livrer un logiciel, pas seulement une fonctionnalité qui s'exécute une fois sur votre poste.

### C.1 — Tests automatisés, objectif réaliste et vérifiable

Un taux de couverture arbitraire n'est pas exigé : un nombre et une nature de tests précis le sont.

- **Au moins huit tests unitaires** sur de la logique métier pure : règles de capacité (refus au-delà de la limite, y compris en cas d'égalité stricte), règles de validation croisée du formulaire de la séance 6, sérialisation aller-retour d'au moins un modèle (`toJson` puis `fromJson` reproduit l'objet initial), calculs de pagination (dernière page partielle, page hors bornes, `total` à zéro).
- **Au moins trois tests de widget** sur des composants critiques : par exemple la carte d'événement affichant correctement un état de jauge à capacité atteinte, un formulaire refusant la soumission sur une entrée invalide, un écran affichant le bon état parmi les quatre exigés en Partie B selon la donnée injectée.
- **Au moins un test sur un `ChangeNotifier`** vérifiant que `notifyListeners` est effectivement appelé au bon moment et pas à un moment incorrect (par exemple : pas de notification si l'opération est refusée par une règle métier).
- **Au moins un test du comportement en cas d'échec réseau**, à l'aide d'un double du client HTTP (simulacre écrit à la main ou paquet de mocks au choix) forçant un code d'erreur ou un délai, vérifiant que la couche appelante produit l'état d'erreur attendu et non une exception non rattrapée.

Contrainte non négociable : la logique métier doit être **testable sans Flutter**, donc sans le moindre import de widget dans les fichiers testés par les tests unitaires de logique pure. L'exécution de `flutter test` dans son ensemble doit être **reproductible sans réseau réel et sans Firebase réel** : tout test qui échoue faute de connexion ou de projet Firebase configuré est un test mal conçu, pas un aléa acceptable.

### C.2 — Nettoyage et artefact de publication

- `flutter analyze` ne remonte **aucun avertissement**.
- Aucun code mort (fonction, classe ou fichier non atteint depuis un point d'entrée ou un test).
- Aucune impression de débogage (`print`, `debugPrint` oublié) dans le code livré.
- Un `README.md` d'exploitation (contenu détaillé en section Livrables).
- Génération d'un **artefact de publication en mode release** (`flutter build apk --release` ou `flutter build appbundle --release`, éventuellement `flutter build ios --release` si l'environnement le permet) et rédaction, dans le `README.md`, de la liste des étapes qui restent à accomplir pour une publication réelle sur un magasin d'applications : identifiant d'application définitif, icône d'application, écran de démarrage, signature de l'artefact, stratégie de versionnement (`pubspec.yaml` : `version:`), et permissions déclarées. Ces étapes sont à **lister et justifier**, pas nécessairement à accomplir intégralement.

### C.3 - Revue de code par un assistant d'IA

Cette partie prolonge directement le livrable `USAGE-IA.md` : elle en est un usage exigé, pas une entrée facultative parmi d'autres.

Soumettez votre code à un assistant d'IA générative pour une revue de code ciblée sur l'architecture et la robustesse. Triez ensuite chacune de ses remarques dans exactement l'une de ces trois catégories, chaque tri devant être argumenté :

- **retenue** : la remarque était pertinente, vous l'avez appliquée ;
- **écartée à tort par l'IA** : l'IA a signalé un problème qui n'en est pas un dans votre contexte, ou a proposé une correction incorrecte — expliquez pourquoi ;
- **écartée à raison par l'apprenant** : la remarque était valide en général mais vous avez choisi consciemment de ne pas l'appliquer, avec une justification technique (contrainte de temps assumée explicitement et non déguisée en choix d'architecture, périmètre du TP, complexité disproportionnée).

**Critères de réussite observables** : le fichier de tests s'exécute intégralement hors ligne ; les quatre familles de tests exigées sont identifiables sans ambiguïté ; `flutter analyze` est propre ; la revue de pair contient bien deux observations d'architecture et des réponses point par point ; le tri des remarques de l'IA distingue explicitement les trois catégories avec argumentation pour chacune.

---

## Partie D — Défi optionnel (bonus, non cumulable)

Choisissez **un seul** des trois défis suivants. Les bonus ne se cumulent pas au-delà du plafond de 2 points, quel que soit le nombre de défis traités : traiter plusieurs défis ne rapporte pas plus que le plafond, et dilue le temps disponible pour les Parties B et C, qui restent prioritaires.

- **Mode hors connexion complet** : file d'attente locale des actions effectuées sans réseau (créer, modifier, s'inscrire), rejouée à la reconnexion, avec une stratégie de résolution de conflit explicite et documentée lorsque l'état distant a changé entre-temps (par exemple : la dernière écriture gagne, avec notification à l'utilisateur, ou refus explicite avec choix manuel).
- **Intégration continue** : configuration d'une automatisation exécutant `flutter analyze` et `flutter test` à chaque envoi sur le dépôt, avec un fichier de configuration versionné et une capture ou un lien démontrant une exécution réussie.
- **Internationalisation en deux langues** : au moins français et anglais, avec formatage des dates et des nombres dépendant de la locale active (via `intl`), et un mécanisme de bascule de langue à l'exécution.

---

## Livrables

Archive `TP10-NOM-Prenom.zip` ou dépôt git (historique conservé, jalon de la Partie A identifiable), contenant :

```
event_planner_app/
├── lib/
│   ├── main.dart
│   ├── presentation/
│   │   ├── routes.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── screens/
│   │   │   ├── catalog_screen.dart
│   │   │   ├── event_detail_screen.dart
│   │   │   ├── organizer_dashboard_screen.dart
│   │   │   ├── event_editor_screen.dart
│   │   │   ├── registration_screen.dart
│   │   │   ├── my_registrations_screen.dart
│   │   │   ├── auth_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   │       ├── event_card.dart
│   │       ├── capacity_gauge.dart
│   │       ├── state_views.dart        // absence / chargement / erreur / session expirée
│   │       └── offline_banner.dart
│   ├── state/
│   │   ├── auth_state.dart
│   │   ├── catalog_state.dart
│   │   ├── registration_cart_state.dart
│   │   └── preferences_state.dart
│   ├── domain/
│   │   ├── models/
│   │   │   ├── event.dart
│   │   │   ├── registration.dart
│   │   │   └── user_profile.dart
│   │   ├── repositories/
│   │   │   ├── event_repository.dart
│   │   │   ├── registration_repository.dart
│   │   │   └── preferences_repository.dart
│   │   └── rules/
│   │       ├── capacity_rule.dart
│   │       └── pagination.dart
│   └── data/
│       ├── remote/
│       │   ├── dummyjson_event_repository.dart
│       │   └── http_client_provider.dart
│       ├── firebase/
│       │   ├── firestore_event_repository.dart
│       │   ├── firestore_registration_repository.dart
│       │   └── firebase_auth_service.dart
│       └── local/
│           └── shared_prefs_repository.dart
├── test/
│   ├── domain/
│   │   ├── capacity_rule_test.dart
│   │   ├── pagination_test.dart
│   │   ├── event_serialization_test.dart
│   │   └── registration_form_validation_test.dart
│   ├── state/
│   │   └── registration_cart_state_test.dart
│   ├── widgets/
│   │   ├── event_card_test.dart
│   │   ├── state_views_test.dart
│   │   └── registration_form_test.dart
│   └── data/
│       └── dummyjson_event_repository_network_failure_test.dart
├── android/ (ou ios/, selon la cible de build release choisie)
├── pubspec.yaml
├── analysis_options.yaml
├── firestore.rules
├── README.md
├── USAGE-IA.md
├── REVUE-PAIR.md
└── captures/                  # démonstration : téléphone étroit, tablette portrait, mode dégradé
```

### `README.md` — sections attendues

Le `README.md` est un document d'exploitation, pas une simple présentation. Il doit contenir au minimum :

1. **Présentation** du produit et de son périmètre fonctionnel réel (ce qui est livré, ce qui ne l'est pas).
2. **Instructions d'installation et d'exécution**, incluant la configuration Firebase nécessaire (sans clé secrète versionnée).
3. **Tableau de traçabilité des huit compétences**, une ligne par compétence de la séance 2 à la séance 9, colonne « fichier(s) qui en atteste(nt) » :

   | Séance | Compétence | Fichier(s) attestant |
   | --- | --- | --- |
   | 2 | Composition et widgets réutilisables | ... |
   | 3 | Navigation à routes nommées | ... |
   | 4 | État partagé par `Provider` | ... |
   | 5 | Consommation d'API REST | ... |
   | 6 | Formulaire à validation croisée | ... |
   | 7 | Préférences persistantes et disque | ... |
   | 8 | Authentification et Firestore protégé | ... |
   | 9 | Adaptatif, animations, accessibilité | ... |

4. **Scénarios de test manuel** reproductibles pour la capacité, le doublon, la pagination et le mode dégradé (Partie B).
5. **Rapport de tests automatisés** : commande d'exécution, nombre de tests par catégorie exigée en Partie C.
6. **Étapes restantes pour une publication réelle** (identifiant d'application, icône, écran de démarrage, signature, versionnement, permissions).
7. **Choix d'architecture** assumés et alternatives écartées, en prévision de la soutenance.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA - TP 10 — <Nom Prénom>

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

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis. L'artefact de publication en mode release généré pour la Partie C.2 doit être conservé et remis séparément (il n'a pas vocation à être recréé depuis les sources nettoyées).

---

## Ressources

- Tests unitaires : https://docs.flutter.dev/cookbook/testing/unit/introduction
- Tests de widget : https://docs.flutter.dev/cookbook/testing/widget/introduction
- Architecture d'application recommandée : https://docs.flutter.dev/app-architecture/recommendations
- Bonnes pratiques de conception d'application : https://docs.flutter.dev/app-architecture/guide
- Déploiement Android : https://docs.flutter.dev/deployment/android
- Déploiement iOS : https://docs.flutter.dev/deployment/ios
- Bonnes pratiques de performance : https://docs.flutter.dev/perf/best-practices
- Analyse statique du code Dart : https://dart.dev/tools/analysis

Les signatures évoluent d'une version de Flutter à l'autre : vérifiez systématiquement sur `api.flutter.dev` que l'API que vous employez existe dans la version retournée par `flutter --version`.

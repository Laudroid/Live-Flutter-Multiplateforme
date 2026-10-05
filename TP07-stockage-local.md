# TP 7 — Stockage local et préférences : rendre l'application utilisable hors connexion

| | |
| --- | --- |
| **Séance de référence** | Séance 7 — Stockage local et préférences |
| **Durée** | 1h45 en autonomie |
| **Modalité** | Individuel |
| **Prérequis** | Séance 5 : `async`/`await`, `Future`, `FutureBuilder` ; Séance 6 : saisie minimale (`TextField` toléré comme moyen) |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (ou version locale ; vérifier avec `flutter --version`), VSCode |

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- persister des données simples localement, sans base de données ni backend ;
- gérer des préférences utilisateur avec l'API `shared_preferences` ;
- lire et écrire des fichiers sur le disque avec `path_provider` et `dart:io` ;
- raisonner sur le cycle de vie des données locales : premier lancement, redémarrage, absence de fichier, fichier corrompu, arrière-plan de l'application.

## Point technique impératif — à lire avant de commencer

`shared_preferences` est en version **2.5.5** dans ce TP. Depuis la version 2.3.0, la documentation officielle du package recommande deux API pour tout code neuf :

- `SharedPreferencesAsync` : tous les accès sont asynchrones (`getString`, `setString`, etc. retournent des `Future`), sans mise en cache locale — chaque lecture interroge la plateforme, donc la valeur est toujours à jour.
- `SharedPreferencesWithCache` : accesseurs synchrones après une initialisation asynchrone, avec un cache local et un rechargement explicite (`reloadCache`). Elle se crée avec `SharedPreferencesWithCache.create(cacheOptions: SharedPreferencesWithCacheOptions(allowList: {...}))`, où `allowList` est l'ensemble des clés que le cache doit gérer.

## Périmètre du TP

**Autorisé et attendu**

- `shared_preferences` : `SharedPreferencesAsync`, `SharedPreferencesWithCache`, `SharedPreferencesWithCacheOptions`
- `path_provider` : `getApplicationDocumentsDirectory`, `getApplicationSupportDirectory`, `getTemporaryDirectory`
- `dart:io` : `File`, `Directory`, lecture et écriture de texte (`readAsString`, `writeAsString`) et d'octets (`readAsBytes`, `writeAsBytes`), `existsSync`, `rename`, `delete`
- `dart:convert` : `jsonEncode`, `jsonDecode`
- `WidgetsBindingObserver` et `AppLifecycleState` pour réagir au passage en arrière-plan
- `FutureBuilder` pour l'initialisation asynchrone des couches de stockage
- Saisie minimale (`TextField` simple) comme moyen de remplir un brouillon, sans validation évaluée

**Hors périmètre — l'usage sera pénalisé**

- `sqflite`, `drift`, `hive`, `isar`, `objectbox` et toute base de données locale
- `flutter_secure_storage` et tout stockage chiffré
- `provider` et tout état global partagé entre écrans (séance 4) : l'état de ce TP reste local à chaque écran
- Tout appel réseau, `http` (séance 5)
- `Form`, `TextFormField`, validation de formulaire comme objet évalué (séance 6)
- Firebase, `firebase_core`, `cloud_firestore` (séance 8)
- Animations, `AnimatedXxx`, `MediaQuery`, `LayoutBuilder` (séance 9)
- Tout framework de test (séance 10)
- `SharedPreferences.getInstance()` (API legacy, voir encadré ci-dessus)

## Mise en situation

*Event Planner* doit rester utilisable sans connexion et sans redémarrer l'application à zéro chaque fois. Deux besoins concrets remontent des utilisateurs : d'une part, l'affichage doit se souvenir de leurs préférences (thème, tri, catégorie filtrée, densité) d'une session à l'autre ; d'autre part, un organisateur qui commence à saisir un événement puis referme l'application par accident — appel entrant, batterie faible, changement d'application — ne doit pas perdre sa saisie. Vous construisez ces deux briques : une couche de préférences typée, et un mécanisme de brouillon persistant sur disque.

---

## Partie A — Prise en main guidée : la couche de préférences

Objectif : construire une couche de préférences isolée, typée métier, qui survit à la fermeture complète de l'application.

1. Ajoutez au `pubspec.yaml` :
   ```yaml
   dependencies:
     shared_preferences: ^2.5.5
     path_provider: ^2.1.6
   ```
   Exécutez `flutter pub get`.

2. Créez `lib/storage/preference_keys.dart`, fichier **unique** déclarant toutes les clés en constantes, chacune assortie de sa valeur par défaut explicite en commentaire :
   ```dart
   /// Clés de préférences déclarées une seule fois. Toute autre partie du code
   /// référence ces constantes : aucune chaîne littérale de clé ailleurs.
   class PreferenceKeys {
     const PreferenceKeys._();

     static const String themeMode = 'pref_theme_mode';       // défaut : 'light'
     static const String defaultSort = 'pref_default_sort';   // défaut : 'date'
     static const String defaultCategoryFilter = 'pref_default_category'; // défaut : '' (aucun filtre)
     static const String displayDensity = 'pref_display_density'; // défaut : 'comfortable'
     static const String lastScreen = 'pref_last_screen';     // défaut : 'home'

     static const Set<String> all = {
       themeMode, defaultSort, defaultCategoryFilter, displayDensity, lastScreen,
     };
   }
   ```

3. Créez `lib/storage/preferences_store.dart` exposant une **interface métier**, pas des appels bruts à la bibliothèque. Aucun écran ne doit importer `shared_preferences` directement.
   ```dart
   enum AppThemeMode { light, dark }
   enum EventSortOrder { date, title, popularity }
   enum DisplayDensity { comfortable, compact }

   abstract class PreferencesStore {
     Future<void> init();

     AppThemeMode get themeMode;
     Future<void> setThemeMode(AppThemeMode mode);

     EventSortOrder get defaultSort;
     Future<void> setDefaultSort(EventSortOrder order);

     String get defaultCategoryFilter; // '' = aucun filtre
     Future<void> setDefaultCategoryFilter(String category);

     DisplayDensity get displayDensity;
     Future<void> setDisplayDensity(DisplayDensity density);

     String get lastScreen;
     Future<void> setLastScreen(String screenName);
   }
   ```
   Fournissez une implémentation concrète `SharedPreferencesStore implements PreferencesStore`. Les accesseurs synchrones (`get themeMode`, etc.) supposent que `init()` a déjà été appelé et complété ; documentez cette contrainte dans un commentaire de classe.

4. **Choix d'API à documenter.** Vous devez choisir entre `SharedPreferencesAsync` et `SharedPreferencesWithCache` pour implémenter `SharedPreferencesStore`. Rédigez dans `README.md` une justification de trois à cinq lignes de votre choix, en vous appuyant sur : la fréquence de lecture de ces valeurs (à chaque construction d'écran), le besoin ou non d'accesseurs synchrones dans les `get` de l'interface ci-dessus, et le coût d'un rechargement explicite. Si vous choisissez `SharedPreferencesWithCache`, l'`allowList` passée à `SharedPreferencesWithCacheOptions` doit être exactement `PreferenceKeys.all`.

5. Câblez `main()` pour attendre `init()` avant d'afficher l'application (un `FutureBuilder` racine, ou un `await` avant `runApp`, au choix — justifiez le choix retenu en une phrase dans `README.md`).

6. Construisez un écran de réglages minimal (`lib/screens/settings_screen.dart`) exposant un sélecteur pour chacune des cinq préférences, appelant les setters de `PreferencesStore`.

**Vérification exigée, captures à l'appui :**
- au tout premier lancement (désinstallation complète ou données de l'application effacées), les cinq préférences affichent leurs valeurs par défaut sans exception — capture de l'écran de réglages à froid ;
- après modification d'au moins trois préférences, fermeture complète de l'application (pas seulement mise en arrière-plan : processus tué) puis réouverture, les valeurs modifiées sont restaurées à l'identique — deux captures, avant fermeture et après réouverture ;
- un redémarrage de l'appareil ou de l'émulateur ne réinitialise pas les préférences.

---

## Partie B — Mise en œuvre autonome : le brouillon d'événement sur disque

Objectif : un organisateur saisit un événement partiellement rempli ; ce brouillon est sérialisé en JSON dans un fichier du répertoire de documents de l'application, restauré à la réouverture, et géré individuellement.

Spécification fonctionnelle, aucune étape n'est détaillée :

- **Modèle.** Un modèle `EventDraft` avec au minimum : un identifiant, un titre, une ville, une date (nullable, tout n'est pas obligatoire dans un brouillon), une catégorie, et un horodatage de dernière modification. `toJson()` et `fromJson()` sont écrits à la main, sans package de génération de code.
- **Nommage de fichier.** Chaque brouillon est un fichier distinct dans le répertoire de documents de l'application. Le nom de fichier est déterministe à partir de l'identifiant du brouillon, et sûr : aucun caractère de l'identifiant ne doit pouvoir produire un chemin invalide ou sortir du répertoire prévu (pas de séparateur de chemin, pas de `..`).
- **Sauvegarde manuelle et automatique.** L'organisateur peut sauvegarder son brouillon explicitement (bouton). Le brouillon en cours d'édition est également sauvegardé **automatiquement lorsque l'application passe en arrière-plan** : implémentez un `WidgetsBindingObserver`, écoutez `AppLifecycleState` sur l'écran d'édition, et déclenchez l'écriture sur `AppLifecycleState.paused` (ou `inactive`, à justifier).
- **Liste des brouillons.** Un écran liste tous les brouillons présents sur le disque, avec pour chacun : titre (ou « (sans titre) » si vide), date de dernière sauvegarde formatée, et taille du fichier occupée sur le disque (en octets, ou en kio si vous préférez, unité affichée).
- **Suppression.** Un brouillon peut être supprimé individuellement. Une action supprime l'ensemble des brouillons.
- **Restauration.** À la réouverture de l'écran d'édition d'un brouillon existant, son contenu est relu depuis le disque et affiché dans les champs de saisie.

**Gestion des cas limites, exigée et vérifiée sur capture ou description reproductible :**

| Cas | Comportement attendu |
| --- | --- |
| Répertoire de documents absent au premier accès | création silencieuse, aucune exception remontée à l'utilisateur |
| Fichier de brouillon absent (identifiant inconnu) | l'écran d'édition s'ouvre sur un brouillon vide, sans exception |
| Fichier de brouillon vide (0 octet) | traité comme un brouillon vide, pas comme une erreur de parsing |
| Fichier de brouillon corrompu (JSON tronqué à la main, à produire pour la démonstration) | l'application affiche un message de dégradation propre (« brouillon illisible », par exemple) ; **aucun plantage**, aucune exception non interceptée |

Produisez pour la dernière ligne un fichier de test que vous tronquez manuellement (par exemple en supprimant la fin de l'accolade fermante) et documentez dans `README.md` la procédure exacte suivie pour le reproduire.

---

## Partie C — Approfondissement (niveau M2) : robustesse et gouvernance des données locales

1. **Écriture atomique.** Une écriture de brouillon interrompue en plein milieu (coupure de courant, application tuée par le système) ne doit jamais laisser un fichier à moitié écrit et donc illisible au prochain lancement. Implémentez le schéma suivant : écrire le contenu dans un fichier temporaire distinct (par exemple `<id>.json.tmp`), puis renommer ce fichier temporaire vers le nom final (`File.rename`), une opération atomique au niveau du système de fichiers sur la plupart des plateformes cibles. **Démontrez le scénario** : simulez une interruption (par exemple en interrompant l'exécution entre l'écriture du fichier temporaire et le renommage, via un point d'arrêt ou un délai artificiel suivi d'une fermeture forcée) et montrez que le fichier final reste soit l'ancienne version intacte, soit la nouvelle version intacte, jamais un état intermédiaire.

2. **Versionnement de schéma.** Ajoutez un champ `schemaVersion` (entier) à la sérialisation JSON des brouillons. Écrivez une migration du schéma version 1 vers un schéma version 2 où un champ existant est renommé (par exemple `city` devient `location`) et un nouveau champ est ajouté avec une valeur par défaut (par exemple `reminderEnabled: false`). Produisez un fichier JSON de test correspondant à l'ancien schéma (version 1, avec `city`), et prouvez par une exécution reproductible que `fromJson` le relit correctement sous la forme du nouveau modèle, sans perte du champ renommé et avec la valeur par défaut appliquée au champ ajouté.

3. **Choix du répertoire.** Complétez dans `README.md` un tableau comparatif des trois répertoires exposés par `path_provider`, selon trois critères : durabilité (survit-il aux mises à jour de l'application, à un nettoyage manuel de l'utilisateur), inclusion dans la sauvegarde système (iCloud, sauvegarde Android), et droit de l'utilisateur à l'effacer depuis les réglages du système.

   | Répertoire | Durabilité | Sauvegardé par le système | Effaçable par l'utilisateur |
   | --- | --- | --- | --- |
   | Documents (`getApplicationDocumentsDirectory`) | ? | ? | ? |
   | Support (`getApplicationSupportDirectory`) | ? | ? | ? |
   | Temporaire (`getTemporaryDirectory`) | ? | ? | ? |

   Justifiez ensuite en trois lignes pourquoi les brouillons de la Partie B sont stockés dans le répertoire choisi et non dans un autre.

4. **Politique de purge.** Écrivez une fonction qui supprime les fichiers d'un répertoire (temporaire, par exemple) dépassant un âge donné (en jours) ou une taille cumulée donnée (en octets) pour l'ensemble du répertoire, au choix du plus contraignant. Documentez le déclenchement choisi (au lancement de l'application, à intervalle régulier, à la demande) et pourquoi.

5. **Travail hors du fil principal.** Identifiez dans votre implémentation l'opération de sérialisation ou désérialisation la plus coûteuse (le plus gros fichier de brouillons, ou une liste de brouillons chargés en une fois) et déplacez-la hors du fil d'interface, par exemple avec `compute()` ou un `Isolate` dédié. Justifiez en deux lignes pourquoi cette opération précise, et pas une autre, mérite ce traitement.

6. **Ce que les préférences ne doivent pas contenir — note obligatoire, une demi-page.** La documentation officielle de `shared_preferences` indique explicitement que les écritures ne sont pas garanties d'être persistées au moment où l'appel retourne, et que ce mécanisme ne doit pas servir à stocker des données critiques. Rédigez dans `README.md` une note d'une demi-page environ répondant à : que ne devez-vous jamais stocker dans les préférences de cette application (données métier comme la liste des événements ou les inscriptions, informations d'authentification, données volumineuses) ? Pourquoi les préférences ne sont-elles pas un magasin de données métier, même pour une petite quantité de données ? Quelle est la différence de contrat entre une préférence et un fichier écrit avec l'écriture atomique de la question 1 ?

---

## Partie D — Défi optionnel : export, import et réinitialisation

Construisez un écran de réglages avancé permettant :

- l'**export** de la totalité des données locales (préférences et brouillons) en un unique fichier JSON, incluant un numéro de version de schéma global et une empreinte (par exemple un hachage du contenu) permettant de contrôler l'intégrité du fichier ;
- l'**import** de ce fichier, avec vérification de l'empreinte avant toute écriture, et **refus explicite** d'un fichier dont le numéro de version de schéma est inconnu (message d'erreur clair, aucune tentative de lecture partielle d'un schéma non reconnu) ;
- une action de **réinitialisation complète** des données locales (préférences remises aux valeurs par défaut, tous les brouillons supprimés), protégée par une boîte de dialogue de confirmation explicite.

Contraintes : aucune dépendance de hachage externe n'est requise (une fonction de hachage simple codée à la main, ou celle de `dart:convert`/`crypto` si vous justifiez l'ajout, est acceptée) ; le format d'export doit rester lisible par un humain qui l'ouvrirait dans un éditeur de texte.

---

## Critères d'évaluation

Noté sur 20, bonus plafonné à 2 points.

| Critère | Points |
| --- | --- |
| **Partie A — couche de préférences** | **5** |
| Clés centralisées dans un seul fichier, valeur par défaut explicite pour chacune | 1 |
| Interface métier typée, aucun écran n'appelle `shared_preferences` directement | 1,5 |
| Choix d'API justifié (`SharedPreferencesAsync` vs `SharedPreferencesWithCache`) | 1 |
| Survie à la fermeture complète et au redémarrage, comportement au premier lancement, captures | 1,5 |
| **Partie B — brouillon persistant** | **6** |
| Modèle avec `toJson`/`fromJson` manuels, nommage de fichier déterministe et sûr | 1,5 |
| Sauvegarde automatique sur passage en arrière-plan via `AppLifecycleState` | 1,5 |
| Liste, restauration, suppression individuelle et globale, date et taille affichées | 1,5 |
| Gestion propre des quatre cas limites (répertoire absent, fichier absent, vide, corrompu) | 1,5 |
| **Partie C — robustesse et gouvernance** | **5** |
| Écriture atomique démontrée sur un scénario d'interruption | 1,5 |
| Migration de schéma version 1 vers 2 prouvée sur une donnée ancienne | 1,5 |
| Tableau comparatif des répertoires et politique de purge | 1 |
| Note sur les données à ne pas stocker en préférences | 1 |
| **Qualité du code** | **2** |
| `flutter analyze` sans avertissement, découpage cohérent, aucune clé ou chemin en littéral dupliqué | 2 |
| **`USAGE-IA.md`** | **2** |
| Complétude, sincérité, esprit critique — y compris sur le piège `SharedPreferences.getInstance()` | 2 |
| **Partie D — export/import (bonus)** | **+2** |

Pénalités : usage d'une notion hors périmètre (base de données locale, stockage chiffré, état global, réseau, formulaire évalué, Firebase, animation) : **−2 points par notion**. Usage de `SharedPreferences.getInstance()` dans le code rendu : **−2 points**. Absence de `USAGE-IA.md` : rendu déclaré incomplet.

---

## Livrables

Archive `TP07-NOM-Prenom.zip` ou dépôt git, contenant :

```
event_planner_storage/
├── lib/
│   ├── main.dart
│   ├── storage/
│   │   ├── preference_keys.dart
│   │   ├── preferences_store.dart
│   │   ├── draft_repository.dart
│   │   └── draft_lifecycle_observer.dart
│   ├── models/
│   │   └── event_draft.dart
│   ├── screens/
│   │   ├── settings_screen.dart
│   │   ├── draft_edit_screen.dart
│   │   └── draft_list_screen.dart
│   └── utils/
│       └── file_size_format.dart
├── pubspec.yaml
├── README.md
├── USAGE-IA.md
└── captures/
    ├── premier_lancement.png
    ├── avant_fermeture.png
    ├── apres_reouverture.png
    └── fichier_corrompu.png
```

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA — TP 7 — <Nom Prénom>

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

Une réponse d'IA reproduite sans être comprise se repère en soutenance. Le barème valorise le refus argumenté autant que l'usage réussi. Si votre assistant d'IA a proposé `SharedPreferences.getInstance()`, c'est un cas d'usage attendu de ce fichier : consignez la sollicitation, la réponse obtenue, et pourquoi vous l'avez refusée.

---

## Ressources

- `shared_preferences` sur pub.dev, section « Migrating to SharedPreferencesAsync » : https://pub.dev/packages/shared_preferences
- `path_provider` sur pub.dev : https://pub.dev/packages/path_provider
- Stockage clé-valeur, documentation officielle Flutter : https://docs.flutter.dev/cookbook/persistence/key-value
- Lecture et écriture de fichiers, documentation officielle Flutter : https://docs.flutter.dev/cookbook/persistence/reading-writing-files
- `AppLifecycleState`, référence API : https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html
- `WidgetsBindingObserver`, référence API : https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html
- `compute()`, référence API : https://api.flutter.dev/flutter/foundation/compute.html

Les signatures évoluent d'une version de Flutter à l'autre : vérifiez systématiquement sur `api.flutter.dev` que l'API que vous employez existe dans la version retournée par `flutter --version`.

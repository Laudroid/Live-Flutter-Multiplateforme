# Event Planner — espace organisateur (corrigé TP 8)

Projet Flutter autonome démontrant un parcours d'authentification Firebase
complet (courriel/mot de passe) et un aperçu de Cloud Firestore avec règles
de sécurité, conformément à l'énoncé du TP 8.

## Avertissement — ce projet ne se lance pas tel quel

`lib/firebase_options.dart` contient des valeurs **fictives**
(`'REMPLACER-PAR-VOTRE-API-KEY'`, etc.). Il a été écrit à la main pour que
le projet compile et que `flutter analyze` passe sans erreur, mais il ne
désigne aucun projet Firebase réel. Tant qu'il n'a pas été régénéré, chaque
lancement affichera l'écran d'erreur d'initialisation (voir
`lib/screens/initialization_error_screen.dart`) au lieu de l'écran de
connexion. C'est un comportement attendu, pas un bogue.

## Mise en route pas à pas

### 1. Console Firebase

1. Aller sur https://console.firebase.google.com et créer un projet (plan
   **Spark**, gratuit — refuser toute proposition de mise à niveau).
2. Dans *Authentication* > *Sign-in method*, activer le fournisseur
   **Email/Password**.
3. Dans *Firestore Database*, créer une base (mode production ou test, peu
   importe : les règles seront écrasées à l'étape 4).

### 2. Outillage local

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Vérifier que `firebase --version` et `flutterfire --version` répondent.

### 3. flutterfire configure — régénérer `firebase_options.dart`

Depuis la racine de ce projet :

```bash
flutterfire configure
```

Sélectionner explicitement le projet créé à l'étape 1 (pas un autre projet
du compte), cocher au moins **Android**. Cette commande **écrase**
`lib/firebase_options.dart` avec les vraies valeurs et génère
`android/app/google-services.json`. C'est le comportement voulu : ne
restaurez pas l'ancien fichier après coup.

### 4. Déployer les règles de sécurité

```bash
firebase use --add        # associer ce dossier au projet créé à l'étape 1
firebase deploy --only firestore:rules
```

Ou copier le contenu de `firestore.rules` directement dans la console,
onglet Firestore Database > Règles.

### 5. Lancer l'application

```bash
flutter pub get
flutter run
```

Créer un compte depuis l'écran d'inscription, puis vérifier dans la console
Firebase (*Authentication* > *Users*) que le compte apparaît bien.

### 6. Émulateurs Firebase (Partie D, optionnel)

Pour travailler sans dépendre du projet en ligne (utile en formation : voir
la note ci-dessous) :

```bash
firebase init emulators   # une seule fois, choisir Auth + Firestore
firebase emulators:start
```

Puis lancer l'application avec le drapeau d'émulation activé :

```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Le basculement est implémenté dans `lib/main.dart` (appel à
`useAuthEmulator` / `useFirestoreEmulator` avant tout autre usage de
Firebase) et piloté par `lib/services/app_config.dart`.

**Note pédagogique (esquisse).** Les émulateurs rendent le TP reproductible
sans compte Google ni projet Firebase partagé : chaque apprenant repart d'un
état local propre, réinitialisable à volonté, sans jamais risquer d'écraser
les données d'un camarade. Pour des tests automatisés (hors périmètre de ce
TP), ils permettent en plus des exécutions rapides et sans effet de bord sur
des données réelles. Cette note reste volontairement une esquisse : voir
`CORRIGE.md`, section Partie D, pour le détail de ce qui est implémenté et
de ce qui ne l'est pas.

## `.gitignore` — `firebase_options.dart` et fichiers de configuration natifs

Ce corrigé **versionne** `lib/firebase_options.dart` (avec ses valeurs
fictives) : c'est un choix délibéré pour ce dépôt de référence, afin que le
projet compile pour quiconque le clone sans étape préalable. Dans un projet
réel individuel, ce fichier peut être versionné ou non selon le contexte :
comme l'énoncé le souligne, il contient des identifiants qui **désignent**
le projet Firebase (apiKey, projectId...), pas un secret cryptographique —
sa divulgation seule ne donne aucun accès en lecture ou écriture aux
données, celui-ci étant entièrement conditionné par `firestore.rules`. On le
versionne donc généralement sans risque particulier, à la différence d'une
vraie clé secrète serveur (clé d'API tierce, jeton de service) qui doit,
elle, systématiquement rester hors dépôt.

`android/app/google-services.json` relève du même raisonnement (identifiant
de projet, pas un secret) et peut être versionné pour la même raison de
reproductibilité. Le `.gitignore` de ce projet ne les exclut donc pas.

## Observations Firestore documentées (Partie C)

- **Cache local et confirmation serveur** : lors d'un `add`, le document
  apparaît immédiatement dans la liste (écriture optimiste du SDK, servie
  depuis le cache local) avant toute confirmation du serveur. L'application
  distingue les deux états via `snapshot.metadata.isFromCache` sur chaque
  document (voir l'icône nuage dans `organizer_home_screen.dart`) : une
  icône orange tant que la donnée n'est vue que localement, verte une fois
  le serveur revenu.
- **Index composite manquant** : la requête de la Partie C
  (`where('ownerId', isEqualTo: uid).orderBy('createdAt', descending: true)`)
  combine un filtre d'égalité et un tri sur un champ différent. Sur une
  collection Firestore réelle sans index composite préexistant pour ce
  couple de champs, le SDK renvoie une `FirebaseException` de code
  `failed-precondition`, avec un message contenant une URL de la console
  Firebase permettant de créer l'index en un clic. Firestore impose cette
  contrainte parce qu'il n'exécute jamais de scan complet de collection à
  l'exécution d'une requête : chaque requête doit pouvoir être servie par un
  index déjà construit, ce qui garantit un temps de réponse borné et
  indépendant de la taille de la collection, au prix de devoir déclarer
  l'index à l'avance plutôt que de laisser le moteur improviser un plan de
  requête coûteux.
- **Hors connexion** : le SDK Firestore maintient une persistance locale par
  défaut sur mobile. Une lecture déjà servie une fois reste disponible hors
  connexion (le `StreamBuilder` continue de recevoir des données, marquées
  `isFromCache: true`). Une écriture (`add`/`update`) est acceptée
  localement et mise en file d'attente ; elle apparaît immédiatement dans
  l'interface (toujours via le cache) mais reste non confirmée
  (`isFromCache: true` en continu) jusqu'au retour de la connexion, moment
  où le SDK la rejoue automatiquement contre le serveur.

Ce projet n'a pas pu être exercé contre un projet Firebase réel dans
l'environnement de production de ce corrigé (voir `CORRIGE.md`, section
"Niveau de validation") : ces trois observations reprennent le comportement
documenté du SDK `cloud_firestore` 6.9.0, à vérifier par le formateur sur un
projet réel avant la séance.

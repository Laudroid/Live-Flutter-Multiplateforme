# TP 8 — Intégration Firebase : l'espace organisateur

| | |
| --- | --- |
| **Séance de référence** | Séance 8 — Intégration Firebase |
| **Durée** | 1h45 en autonomie |
| **Modalité** | Individuel |
| **Prérequis** | Séances 1 à 7 : projet Flutter fonctionnel, formulaires (séance 6), persistance locale (séance 7). Un **compte Google personnel**. Aucune carte bancaire requise : le plan gratuit **Spark** suffit intégralement pour ce TP. |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (vérifier avec `flutter --version`), VSCode, Node.js et npm (pour `firebase-tools`) |

## Prérequis Firebase — à faire avant la séance

Chaque apprenant crée **son propre projet Firebase** :

1. Un compte Google valide (compte personnel ou compte étudiant, peu importe).
2. Un projet créé depuis https://console.firebase.google.com, sur le plan **Spark** (gratuit). Aucune information de paiement n'est demandée pour ce plan ; si la console vous propose une mise à niveau, refusez-la, elle est inutile pour ce TP.
3. Node.js installé (`node --version`), nécessaire à `npm install -g firebase-tools`.

Un projet Firebase créé par erreur ne coûte rien à supprimer : en cas de doute pendant la configuration, il est préférable de recommencer avec un projet neuf que de s'acharner sur une configuration incohérente.

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- configurer un projet Flutter pour qu'il communique avec un projet Firebase réel, via la FlutterFire CLI ;
- implémenter un parcours d'authentification complet par courriel et mot de passe avec `firebase_auth` ;
- observer l'état de connexion avec `authStateChanges` et en déduire une garde d'accès ;
- traduire les échecs d'authentification en messages utilisateur exploitables, sans jamais exposer une exception brute ;
- décrire, à titre d'aperçu, le fonctionnement temps réel de Cloud Firestore et la logique des règles de sécurité côté serveur.

## Périmètre du TP

**Autorisé et attendu**

- `firebase_core` : `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- `firebase_auth` : `createUserWithEmailAndPassword`, `signInWithEmailAndPassword`, `signOut`, `sendPasswordResetEmail`, `sendEmailVerification`, `currentUser`, `authStateChanges()`, `userChanges()`, `updateDisplayName`, `FirebaseAuthException` et ses `code`
- `cloud_firestore`, en **aperçu** seulement (Partie C) : `collection`, `doc`, `add`, `set`, `update`, `delete`, `get`, `snapshots()`, requêtes `where`, `orderBy`, `limit`, `FieldValue.serverTimestamp()`
- `StreamBuilder` pour observer l'état d'authentification et les flux Firestore
- Règles de sécurité Firestore (lecture dans la console, écriture d'un extrait à compléter)
- Émulateurs Firebase (Partie D uniquement)

**Hors périmètre**

- Authentification par fournisseur tiers : Google Sign-In, Apple, téléphone
- Firebase Storage, Cloud Functions, Firebase Cloud Messaging, Analytics, Remote Config
- `provider`, `ChangeNotifier`, `InheritedWidget` ou tout état global au sens de la séance 4 : l'état d'authentification s'observe **uniquement** via `StreamBuilder` sur `authStateChanges()`, pas via un gestionnaire d'état partagé
- Tout appel réseau direct avec `http` (séance 5) : Firebase gère son propre transport
- Validation de formulaire évaluée en tant que telle (séance 6) : un champ de saisie de courriel et de mot de passe est nécessaire comme **moyen** d'obtenir des identifiants, sa validation fine n'est pas l'objet de ce TP
- Animations, `MediaQuery`, disposition responsive avancée (séance 9)
- Tests automatisés (séance 10)

## Mise en situation

*Event Planner* a besoin d'un espace réservé aux organisateurs : chacun doit créer un compte, se connecter, et retrouver, même après avoir quitté l'application, la liste des événements qu'il a créés. Cette liste doit se mettre à jour en direct si un autre organisateur, ou vous-même depuis la console, modifie un événement. Jusqu'ici, l'application ne connaissait aucun utilisateur ; à partir de ce TP, chaque organisateur a une identité, et chaque événement lui appartient.

---

## Partie A — Prise en main guidée : connexion et compte

Objectif : obtenir un projet qui communique avec Firebase, avec un compte utilisateur qui apparaît réellement dans la console.

1. **Créer le projet Firebase.** Depuis https://console.firebase.google.com, créez un projet nommé par exemple `event-planner-<votre nom>`. Restez sur le plan Spark.
2. **Installer l'outillage.**
   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
   Vérification intermédiaire : `firebase --version` et `flutterfire --version` répondent sans erreur. Si `flutterfire` n'est pas reconnu après installation, vérifiez que le répertoire `pub global` de Dart est bien dans votre `PATH`.

3. **Créer le projet Flutter et le pubspec.**
   ```bash
   flutter create event_planner_auth
   cd event_planner_auth
   ```
   Ajoutez au `pubspec.yaml` :
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     firebase_core: ^4.14.0
     firebase_auth: ^6.6.1
     cloud_firestore: ^6.9.0
   ```
   `flutter pub get`. Vérification : aucune erreur de résolution de dépendances.
4. **Générer la configuration.**
   ```bash
   flutterfire configure
   ```
   Sélectionnez explicitement le projet Firebase créé à l'étape 1. Cochez au moins la plateforme **Android**. Cette commande génère `lib/firebase_options.dart` et, selon les plateformes choisies, `android/app/google-services.json`.
   Vérification : le fichier `lib/firebase_options.dart` existe et contient une classe `DefaultFirebaseOptions` avec un `apiKey`, un `projectId` correspondant au projet créé.

5. **Point de vigilance — nature de ces fichiers.** `firebase_options.dart`, `google-services.json` et `GoogleService-Info.plist` contiennent des identifiants qui **désignent** votre projet Firebase, pas des secrets cryptographiques : leur divulgation ne donne à elle seule aucun accès en lecture ou écriture à vos données. La sécurité de vos données repose entièrement sur les **règles de sécurité Firestore** (Partie C), pas sur la confidentialité de ces fichiers. Cela ne dispense pas d'un choix réfléchi de gestion de version : rédigez dans `README.md` un paragraphe justifiant votre décision de versionner ou non ces fichiers dans le `.gitignore` du projet, en distinguant explicitement ce raisonnement de celui qui s'appliquerait à une vraie clé secrète (clé serveur, jeton d'API tiers).

6. **Initialiser Firebase dans `main`.**
   ```dart
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     try {
       await Firebase.initializeApp(
         options: DefaultFirebaseOptions.currentPlatform,
       );
     } catch (e) {
       // l'application doit informer l'utilisateur, pas planter silencieusement
     }
     runApp(const EventPlannerApp());
   }
   ```
   Complétez la gestion de l'échec : si `Firebase.initializeApp` lève une exception, l'application doit démarrer sur un écran d'erreur explicite plutôt que de laisser planter le widget racine.

7. **Activer le fournisseur courriel/mot de passe.** Dans la console, section *Authentication* > *Sign-in method*, activez le fournisseur *Email/Password*. Vérification : le fournisseur apparaît « activé » dans la liste.

8. **Créer un compte et se connecter.** Construisez un écran minimal avec deux champs de saisie et deux boutons appelant respectivement `createUserWithEmailAndPassword` et `signInWithEmailAndPassword`. Affichez, une fois connecté, `FirebaseAuth.instance.currentUser?.uid` et `currentUser?.email`. Ajoutez un bouton de déconnexion appelant `signOut()`.

9. **Vérification finale obligatoire.** Ouvrez la console Firebase, onglet *Authentication* > *Users*. Le compte que vous avez créé depuis l'application doit y apparaître, avec son adresse courriel et sa date de création. Une capture de cet écran est à joindre aux livrables.

**Échecs classiques à anticiper et diagnostiquer** :

| Symptôme | Cause probable |
| --- | --- |
| Échec de résolution Gradle après `flutterfire configure` | version minimale du SDK Android (`minSdkVersion`) trop basse dans `android/app/build.gradle` : `firebase_auth` exige au minimum le niveau indiqué par son changelog |
| `flutterfire configure` propose le mauvais projet ou aucun projet | mauvais compte actif dans `firebase login`, ou projet créé sous un autre compte Google |
| Erreur liée à une empreinte SHA absente | pertinent uniquement si vous ajoutez plus tard un fournisseur nécessitant une empreinte (hors périmètre ici) ; à mentionner mais pas à corriger dans ce TP |
| `FirebaseException` au lancement, message évoquant une plateforme non configurée | plateforme non cochée lors de `flutterfire configure`, ou fichier `google-services.json` absent du dossier attendu |

**Critères de réussite observables** : le compte créé est visible dans la console ; la connexion avec les mêmes identifiants réussit après redémarrage à froid de l'application ; la déconnexion ramène `currentUser` à `null` ; l'échec d'initialisation de Firebase est géré, pas laissé sous forme d'exception non interceptée.

---

## Partie B — Mise en œuvre autonome : parcours d'authentification complet

Objectif : un parcours d'authentification. Aucune étape n'est détaillée : la spécification fonctionnelle suffit.

L'application comporte :

1. **Un écran de connexion** (courriel, mot de passe, bouton de connexion, lien vers l'inscription, lien vers la réinitialisation du mot de passe).

2. **Un écran d'inscription** (courriel, mot de passe, confirmation du mot de passe, création du compte).

3. **Une réinitialisation du mot de passe par courriel**, déclenchée par `sendPasswordResetEmail`, avec confirmation visuelle que l'envoi a été demandé.

4. **Une garde d'accès** : les écrans de l'espace organisateur (Partie C) sont **structurellement inatteignables** sans session valide, pas seulement masqués par une condition d'affichage locale. La restauration de session doit être automatique au redémarrage de l'application : un utilisateur déjà connecté ne doit jamais revoir l'écran de connexion au lancement. Cette garde s'appuie exclusivement sur un `StreamBuilder` écoutant `FirebaseAuth.instance.authStateChanges()` à la racine de la navigation ; aucun état global maison ne doit dupliquer cette information.

5. **Une déconnexion** qui ramène à l'écran de connexion en vidant la pile de navigation : il doit être impossible d'appuyer sur le bouton *retour* du système et de revenir à un écran de l'espace privé après déconnexion.

6. **Vérification d'adresse courriel** : après inscription, `sendEmailVerification` est appelé, et l'état de vérification (`user.emailVerified`, actualisé via `userChanges()` ou un rafraîchissement explicite via `reload()`) est prise en compte dans l'interface ; a minima un bandeau ou un écran informant l'utilisateur non vérifié, sans nécessairement bloquer l'accès.

7. **Mise à jour du profil** : un écran ou une action permettant d'appeler `updateDisplayName` et de voir le nom affiché mis à jour dans l'interface après l'opération.

**Traduction obligatoire des erreurs.** Il est formellement interdit d'afficher `e.toString()` ou `e.message` brut d'une `FirebaseAuthException` à l'utilisateur. Une fonction de traduction centralisée (par exemple `lib/utils/auth_error_translator.dart`) doit couvrir au minimum les six codes suivants, avec un message français exploitable par un utilisateur non technique :

| Code `FirebaseAuthException` | Message utilisateur attendu (exemple, à rédiger vous-même) |
| --- | --- |
| `email-already-in-use` | ... |
| `invalid-email` | ... |
| `weak-password` | ... |
| `invalid-credential` / `wrong-password` | ... |
| `too-many-requests` | ... |
| `operation-not-allowed` | ... |

Tout code non reconnu doit retomber sur un message générique, jamais sur le contenu brut de l'exception.

**Critères de réussite observables** : impossible de revenir à l'espace organisateur après déconnexion via le bouton retour ; session restaurée automatiquement après relance de l'application, sans écran de connexion parasite ; les six codes du tableau ci-dessus produisent chacun un message distinct et compréhensible, vérifié en provoquant réellement chaque erreur (mauvais mot de passe, courriel déjà utilisé, etc.) plutôt qu'en le supposant.

---

## Partie C — Aperçu Firestore et sécurité

1. **Modélisation.** Créez une collection `events`. Chaque document représente un événement et porte au minimum : `title`, `ownerId` (l'UID de l'organisateur connecté au moment de la création), `createdAt` (`FieldValue.serverTimestamp()`), et les champs métier de votre choix (date, lieu...). N'utilisez jamais l'UID comme identifiant de document de l'événement : un organisateur crée plusieurs événements.

2. **Affichage temps réel.** Affichez la liste des événements de l'organisateur connecté (`where('ownerId', isEqualTo: uid)`, éventuellement `orderBy('createdAt')`) via un `StreamBuilder` sur `.snapshots()`. **Démontrez, captures à l'appui**, qu'une modification faite directement depuis la console Firebase (éditer un champ d'un document) se propage à l'écran de l'application sans action de l'utilisateur ni redémarrage.

3. **Règles de sécurité — écriture et déploiement.** Rédigez dans `firestore.rules` des règles qui :
   - interdisent toute lecture et toute écriture sur `events` à un client non authentifié ;
   - autorisent un organisateur authentifié à lire et modifier **uniquement** les documents dont `ownerId` correspond à son propre UID.

   Squelette à compléter :
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /events/{eventId} {
         allow read, write: if /* à compléter */;
       }
     }
   }
   ```
   Déployez ces règles (console ou `firebase deploy --only firestore:rules`).

4. **Preuve du refus.** Démontrez, par une capture d'écran ou un journal, qu'une tentative de lecture non authentifiée échoue, et qu'une tentative de modification d'un événement appartenant à un autre organisateur échoue également. Dans l'application, cet échec (`FirebaseException` de code `permission-denied`) doit être traité comme un **cas fonctionnel normal** — message à l'utilisateur, écran stable — et non comme un plantage non intercepté.

5. **Écriture locale et confirmation serveur.** Observez et documentez dans `README.md` : lors d'un `add` ou d'un `update`, la mise à jour apparaît localement avant confirmation serveur (cache offline du SDK). Utilisez le champ `metadata.isFromCache` d'un `DocumentSnapshot` ou `QuerySnapshot` pour distinguer une donnée provenant du cache local d'une donnée confirmée par le serveur, et affichez cette distinction (même sous forme minimale, par exemple une icône) dans votre liste.

6. **Coût d'un index manquant.** Construisez volontairement une requête combinant un `where` sur un champ et un `orderBy` sur un autre champ, sans index composite existant. Capturez le message d'erreur retourné par Firestore, qui fournit un lien de création directe de l'index. Expliquez dans `README.md`, en deux ou trois phrases, pourquoi Firestore impose cette contrainte au lieu de scanner la collection.

7. **Comportement hors connexion.** Coupez la connexion réseau de l'appareil ou de l'émulateur, effectuez une lecture puis une écriture, et documentez ce qui reste utilisable grâce à la persistance locale, et ce qui échoue ou reste en attente.

8. **Libération des abonnements.** Tout `StreamSubscription` souscrit manuellement (hors usage direct d'un `StreamBuilder`, qui gère son propre cycle de vie) doit être annulé dans `dispose()`. Justifiez dans le code, par un commentaire, chaque abonnement conservé au-delà de la durée de vie du widget qui l'a créé.

9. **Note d'ingénierie (une demi-page environ).** Rédigez dans `NOTE-SECURITE.md` une explication de la raison pour laquelle une règle de sécurité serveur ne peut **jamais** être remplacée par une vérification côté client (masquer un bouton, filtrer une liste affichée). Appuyez-vous sur un scénario concret impliquant un client modifié ou un appel direct à l'API REST Firestore.

**Critères de réussite observables** : la propagation console → application est démontrée par capture ; les règles refusent effectivement les deux scénarios non autorisés, refus démontré et non supposé ; l'application ne plante sur aucun `permission-denied` ; la note de sécurité argumente sur un scénario concret.

---

## Partie D — Défi optionnel : émulateurs Firebase

Faites fonctionner l'ensemble du TP (Auth et Firestore) contre les **émulateurs Firebase locaux** plutôt que contre le projet en ligne, en basculant par un drapeau de configuration (constante booléenne ou variable d'environnement) plutôt qu'en dupliquant le code.

```bash
firebase init emulators
firebase emulators:start
```

Côté Flutter, avant tout autre appel Firebase :
```dart
if (useEmulators) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

Rédigez une note d'une demi-page sur l'intérêt des émulateurs pour la reproductibilité d'une formation (chaque apprenant repart d'un état propre, sans dépendre d'un compte Google ni d'un projet en ligne partagé) et pour les tests automatisés (rapidité, absence d'effets de bord sur des données réelles, possibilité de réinitialiser l'état entre deux exécutions).

---

## Livrables

Archive `TP08-NOM-Prenom.zip` ou dépôt git, contenant :

```
event_planner_auth/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── models/app_user.dart
│   ├── models/event.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── reset_password_screen.dart
│   │   ├── organizer_home_screen.dart
│   │   └── profile_screen.dart
│   ├── services/auth_gate.dart
│   └── utils/auth_error_translator.dart
├── firestore.rules
├── pubspec.yaml
├── README.md
├── NOTE-SECURITE.md
├── USAGE-IA.md
└── captures/
    ├── console-utilisateur-cree.png
    ├── propagation-temps-reel.png
    └── refus-regles-securite.png
```

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis. Le fichier `.gitignore` remis doit refléter le choix justifié dans `README.md` concernant `firebase_options.dart` et les fichiers de configuration natifs.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA — TP 8 — <Nom Prénom>

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

Une réponse d'IA reproduite sans être comprise se repère en soutenance. Le barème valorise le refus argumenté autant que l'usage réussi. Pour ce TP en particulier, tout cas où l'IA a proposé une méthode, un paramètre ou une classe FlutterFire n'existant pas dans les versions indiquées en en-tête (ou dépréciée depuis) doit apparaître explicitement comme motif de refus ou de correction dans une entrée.

---

## Ressources

- Configuration FlutterFire (console, CLI, plateformes) : https://firebase.google.com/docs/flutter/setup
- Démarrer avec Firebase Auth en Flutter : https://firebase.google.com/docs/auth/flutter/start
- Démarrage rapide Cloud Firestore : https://firebase.google.com/docs/firestore/quickstart
- Règles de sécurité Firestore : https://firebase.google.com/docs/rules
- Suite d'émulateurs Firebase locaux : https://firebase.google.com/docs/emulator-suite
- Package `firebase_auth` sur pub.dev (référence de version) : https://pub.dev/packages/firebase_auth
- Package `cloud_firestore` sur pub.dev (référence de version) : https://pub.dev/packages/cloud_firestore

Les API FlutterFire évoluent d'une version mineure à l'autre : vérifiez systématiquement la signature exacte contre la documentation en ligne du jour et contre la version installée (`flutter pub deps` ou contenu de `pubspec.lock`), plutôt que contre une réponse d'assistant d'IA entraînée sur une version antérieure.

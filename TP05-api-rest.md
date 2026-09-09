# TP 5 — Consommation d'API REST : l'annuaire distant

| | |
| --- | --- |
| **Séance de référence** | Séance 5 — Consommation d'API REST |
| **Durée** | 3h encadrées, finalisation en autonomie |
| **Modalité** | Individuel |
| **Prérequis** | Séances 1 à 4 : projet Flutter fonctionnel, composition de widgets, navigation, notions d'état (`setState`, `ChangeNotifier`) |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (ou version locale ; vérifier avec `flutter --version`), VSCode |

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- communiquer avec un serveur distant via HTTP à l'aide du package `http` ;
- construire des requêtes avec `Uri.https` et vérifier le code de statut d'une réponse avant tout traitement ;
- modéliser des données reçues en JSON dans des classes Dart, avec un `fromJson` écrit à la main et une conversion de types défensive ;
- gérer l'asynchronisme et le parsing JSON sans bloquer l'interface ;
- piloter l'affichage des trois états d'une requête (attente, erreur, succès) avec `FutureBuilder` et `ConnectionState`.

## Périmètre du TP

**Autorisé et attendu**

- `package:http` : `http.get`, `http.post`, `http.Client`, en-têtes, délai d'expiration (`timeout`)
- `dart:convert` : `jsonDecode`, `jsonEncode`
- `Future`, `async`/`await`, `try`/`catch`, hiérarchie d'exceptions personnalisée
- Classes de modèles avec `fromJson` et `toJson` écrits à la main (aucune génération de code)
- `FutureBuilder`, `ConnectionState`
- `RefreshIndicator`, `ScrollController` pour la pagination au défilement
- `Uri.https` pour construire les requêtes
- `compute` (Partie C) pour déporter un décodage JSON coûteux hors du fil principal

**Hors périmètre — l'usage sera pénalisé**

- `dio`, `chopper`, `retrofit` : tout client HTTP autre que `package:http`
- `freezed`, `json_serializable` et toute génération de code : le parsing s'écrit à la main
- `provider` et tout état global au sens de la séance 4 : l'état asynchrone de ce TP est porté localement par le widget qui l'affiche, via `FutureBuilder`
- `StreamBuilder` et tout flux temps réel : ce TP travaille sur des requêtes ponctuelles, pas sur un flux
- `Form`, `TextFormField`, `TextEditingController` avec validation (séance 6) : pour la recherche, un champ de saisie minimal ou des boutons de mots-clés prédéfinis suffisent, sans validation de formulaire
- Cache persistant sur disque, `SharedPreferences` (séance 7)
- Firebase, `firebase_core`, `cloud_firestore` (séance 8)
- Animations, `MediaQuery`, `LayoutBuilder` (séance 9)
- Tout test automatisé (séance 10) : la vérification de ce TP se fait par observation manuelle et captures d'écran

## API imposée

Ce TP utilise **DummyJSON** (`https://dummyjson.com`), une API publique sans clé. Les points d'entrée suivants sont vérifiés au 2 septembre 2026 et doivent être utilisés tels quels :

| Usage | Requête |
| --- | --- |
| Liste paginée d'utilisateurs | `GET https://dummyjson.com/users?limit=20&skip=0&select=firstName,lastName,email,image,company` |
| Recherche par mot-clé | `GET https://dummyjson.com/users/search?q=Emily&limit=10` |
| Détail d'un utilisateur | `GET https://dummyjson.com/users/5` |
| Latence simulée | ajouter `&delay=1500` à n'importe quelle requête ci-dessus |
| Erreur serveur forcée | `GET https://dummyjson.com/http/500` (renvoie effectivement un code 500) |
| Écriture simulée (Partie D) | `POST https://dummyjson.com/users/add` |

La réponse de l'endpoint de liste a la forme suivante :

```json
{
  "users": [
    {
      "id": 1,
      "firstName": "Emily",
      "lastName": "Johnson",
      "email": "emily.johnson@x.dummyjson.com",
      "image": "https://dummyjson.com/icon/emilys/128",
      "company": { "name": "Dooley, Kiehn and Runolfsdottir" }
    }
  ],
  "total": 208,
  "skip": 0,
  "limit": 20
}
```

Le champ `total` (208 utilisateurs disponibles) rend la pagination réelle et testable : vous pouvez vérifier qu'elle s'arrête au bon moment sans deviner une valeur. Le paramètre `&delay` et l'endpoint `/http/500` rendent les états de chargement et d'erreur reproductibles à la demande, sans dépendre d'une coupure réseau réelle : appuyez-vous explicitement sur ces deux mécanismes dans vos protocoles de test, aux deux parties A et B.

Secours en cas d'indisponibilité de DummyJSON : `https://jsonplaceholder.typicode.com` (adapter les modèles en conséquence, la structure des ressources diffère).

Version imposée : `http: ^1.6.0`. Aucun autre paquet réseau.

## Mise en situation

*Event Planner* a besoin d'un annuaire des participants et d'un accès au catalogue d'utilisateurs, alimentés depuis un service distant plutôt que depuis des données codées en dur comme aux séances précédentes. L'organisateur doit pouvoir parcourir la liste des personnes inscrites au système, en rechercher une par nom, consulter sa fiche détaillée, et le faire dans des conditions réseau réalistes : une connexion parfois lente, parfois en erreur. Le serveur distant utilisé dans ce TP est un jeu d'essai public (DummyJSON) qui joue ici le rôle du futur backend d'Event Planner.

---

## Partie A — Prise en main guidée : premier appel et premier affichage

Objectif : réaliser la chaîne complète d'un appel réseau, du fichier `pubspec.yaml` jusqu'à l'affichage, sur un seul endpoint.

1. Créez un projet (`flutter create event_planner_api`) et ajoutez la dépendance :
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     http: ^1.6.0
   ```
   Exécutez `flutter pub get` et vérifiez la version résolue dans `pubspec.lock`.

2. Créez une couche client isolée dans `lib/api/`. Le reste de l'application ne doit jamais appeler `http.get` directement : il passe par cette couche. Squelette attendu, `lib/api/users_api.dart` :
   ```dart
   class UsersApi {
     static const _host = 'dummyjson.com';

     Future<List<Participant>> fetchUsers({int limit = 20, int skip = 0}) async {
       // construire l'URI avec Uri.https, exécuter la requête, vérifier le code
       // de statut, décoder le JSON, transformer en List<Participant>
     }
   }
   ```

3. Construisez l'URI avec `Uri.https`, sans concaténation de chaînes :
   ```dart
   final uri = Uri.https(_host, '/users', {
     'limit': '$limit',
     'skip': '$skip',
     'select': 'firstName,lastName,email,image,company',
   });
   ```

4. Exécutez la requête avec `http.get(uri)`. **Avant de décoder quoi que ce soit**, vérifiez `response.statusCode`. Un code différent de 200 doit interrompre le traitement et signaler l'anomalie ; ne décodez jamais un corps de réponse dont vous n'avez pas validé le code.

5. Écrivez à la main le modèle `Participant` dans `lib/models/participant.dart` :
   ```dart
   class Participant {
     const Participant({
       required this.id,
       required this.firstName,
       required this.lastName,
       required this.email,
       required this.imageUrl,
       required this.companyName,
     });

     final int id;
     final String firstName;
     final String lastName;
     final String email;
     final String imageUrl;
     final String companyName;

     factory Participant.fromJson(Map<String, dynamic> json) {
       // conversion défensive : voir consigne ci-dessous
     }
   }
   ```
   La conversion doit rester correcte dans les cas suivants, que vous devez tester en modifiant temporairement un JSON de test local (pas en cassant l'API distante) :
   - un champ attendu est absent de la map ;
   - un champ est présent mais vaut `null` ;
   - un champ numérique est reçu sous forme de chaîne (`"id": "5"`) ;
   - le sous-objet `company` est absent ou ne contient pas `name`.
   Une valeur de repli explicite (chaîne vide, 0, ou un libellé du type `"Non renseigné"`) doit être utilisée dans chacun de ces cas ; une exception non interceptée à la lecture d'un champ manquant est un défaut.

6. Affichez la liste dans un écran `lib/screens/directory_screen.dart` à l'aide d'un `FutureBuilder<List<Participant>>`, en gérant explicitement les trois branches :
   ```dart
   FutureBuilder<List<Participant>>(
     future: _futureParticipants,
     builder: (context, snapshot) {
       if (snapshot.connectionState == ConnectionState.waiting) {
         // indicateur de chargement
       }
       if (snapshot.hasError) {
         // message d'erreur, pas la trace brute
       }
       if (snapshot.hasData) {
         // ListView.builder sur snapshot.data!
       }
       // ...
     },
   )
   ```

7. Vérifiez et capturez à l'écran les deux comportements suivants, chacun devant figurer dans vos captures de rendu :
   - **chargement visible** : ajoutez `&delay=1500` à la requête (via un paramètre supplémentaire de `Uri.https`) et confirmez que l'indicateur de chargement reste affiché pendant au moins 1,5 seconde avant la liste ;
   - **erreur visible** : remplacez temporairement l'appel par une requête vers `https://dummyjson.com/http/500` et confirmez que la branche `hasError` s'affiche avec un message compréhensible, sans que l'application ne plante.

**Critères de réussite observables** : le code de statut est vérifié avant tout `jsonDecode` ; les quatre cas limites de `fromJson` ne lèvent aucune exception ; les trois branches du `FutureBuilder` sont visuellement distinctes ; le chargement de 1,5 seconde et l'erreur 500 sont démontrés par capture.

---

## Partie B — Mise en œuvre autonome : l'écran d'annuaire complet

Objectif : livrer un écran d'annuaire exploitable, avec pagination, recherche, détail et rafraîchissement. Aucune étape n'est détaillée : la spécification fonctionnelle suffit.

L'écran doit fournir :

1. **Liste paginée par pages de 20.** Utilisez `skip` et `limit` pour récupérer les pages successives, et le champ `total` de la réponse pour savoir quand cesser de charger (ne demandez pas de page au-delà de `total`). Le chargement de la page suivante se déclenche au défilement, avant que l'utilisateur n'atteigne le bas visible de la liste (anticipation raisonnable, par exemple à l'approche des trois derniers éléments).

2. **Indicateur de chargement en pied de liste distinct du chargement initial.** Le premier chargement (page 0) affiche un état plein écran ; le chargement d'une page suivante affiche un indicateur discret en bas de la liste existante, sans faire disparaître les éléments déjà chargés.

3. **Recherche par mot-clé** sur `/users/search`, déclenchée par un champ de saisie minimal ou par des boutons de mots-clés prédéfinis (rappel : aucune validation de formulaire n'est attendue à ce stade, ce sujet appartient à la séance 6). La recherche interrompt la pagination en cours et repart d'une liste neuve.

4. **État vide distinct de l'état d'erreur.** Une recherche sans résultat (liste vide renvoyée avec un code 200) doit afficher un message dédié (« aucun résultat pour... »), visuellement et textuellement différent du message affiché en cas d'échec réseau ou serveur. Confondre les deux états est une erreur de conception à éviter explicitement.

5. **Écran de détail** alimenté par `GET /users/{id}`, ouvert depuis un élément de la liste, affichant au minimum les champs récupérés plus au moins un champ supplémentaire non présent dans la liste (par exemple l'adresse ou le numéro de téléphone, disponibles sur l'endpoint de détail).

6. **Rafraîchissement par tirage vers le bas** (`RefreshIndicator`) qui remet la pagination à zéro : après un tirage, la liste repart de `skip=0`, comme un premier chargement, sans mélanger anciennes et nouvelles pages.

7. **Message d'erreur exploitable.** Quel que soit le point d'échec (réseau, code 500, JSON illisible), l'utilisateur voit un texte en français compréhensible (« le service est momentanément indisponible, veuillez réessayer »), jamais une trace d'exception Dart brute (`Exception: ...` ou une pile d'appel) affichée directement dans l'interface.

**Critères de réussite observables** : la pagination s'arrête exactement à `total` sans requête superflue ; l'indicateur de pied de liste et l'indicateur plein écran sont visuellement différents ; une recherche sans résultat et une erreur serveur produisent deux écrans différents ; le tirage vers le bas repart bien de `skip=0` (vérifiable en journalisant les requêtes émises).

---

## Partie C — Approfondissement (niveau M2) : robustesse du client réseau

Cette partie évalue votre capacité à produire un client réseau défendable en production, pas seulement fonctionnel en démonstration.

1. **Instance de client réutilisée.** Remplacez les appels statiques (`http.get`, `http.post`) par une unique instance de `http.Client` conservée dans l'état du widget porteur (ou dans votre couche `lib/api/`), fermée explicitement dans `dispose()` :
   ```dart
   class _DirectoryScreenState extends State<DirectoryScreen> {
     final http.Client _client = http.Client();

     @override
     void dispose() {
       _client.close();
       super.dispose();
     }
   }
   ```
   Justifiez en une phrase dans le `README.md` la différence de comportement avec des appels statiques répétés (réutilisation de connexion sous-jacente).

2. **Délai d'expiration explicite.** Chaque requête est bornée par un `.timeout(Duration(seconds: ...))`. Le dépassement de délai est intercepté et traduit en message distinct des autres erreurs (« délai dépassé », pas « erreur inconnue »).

3. **Hiérarchie d'exceptions applicatives propres.** Définissez dans `lib/api/exceptions.dart` une hiérarchie couvrant au minimum :
   ```dart
   sealed class ApiException implements Exception {
     const ApiException(this.message);
     final String message;
   }

   class NetworkException extends ApiException { const NetworkException(super.message); }
   class ServerException extends ApiException { const ServerException(super.message, this.statusCode); final int statusCode; }
   class NotFoundException extends ApiException { const NotFoundException(super.message); }
   class DecodingException extends ApiException { const DecodingException(super.message); }
   ```
   Chaque type correspond à une cause distincte (panne réseau, code 5xx, code 404, corps de réponse illisible) et porte un message destiné à l'affichage, différent selon le type.

4. **Nouvelle tentative avec temporisation croissante.** En cas d'erreur transitoire uniquement (`NetworkException`, `ServerException` sur 5xx — jamais sur 404), une nouvelle tentative est effectuée, plafonnée à trois essais, avec un délai croissant entre chaque tentative (par exemple 1 s, puis 2 s, puis 4 s). Démontrez ce comportement à l'aide de `/http/500` et d'un journal de requêtes (impressions horodatées en console suffisent) montrant les trois tentatives et leur espacement croissant.

5. **Décodage JSON déporté avec `compute`.** Pour la réponse de liste (potentiellement volumineuse), déportez le `jsonDecode` et la construction de la liste de modèles hors du fil principal avec `compute` :
   ```dart
   Future<List<Participant>> _parseUsers(String body) {
     return compute(_parseUsersInBackground, body);
   }

   List<Participant> _parseUsersInBackground(String body) {
     // exécuté dans un isolate séparé
   }
   ```
   Justifiez dans le `README.md` pourquoi cette étape n'a d'intérêt mesurable qu'à partir d'un certain volume de données, et pas sur une page de 20 éléments.

6. **Le piège du `FutureBuilder` recréé à chaque `build`.** Identifiez et corrigez le défaut suivant, central à cette séance : passer directement un appel de méthode au paramètre `future` d'un `FutureBuilder` provoque la ré-exécution de la requête à chaque recomposition du widget parent, y compris lors d'événements sans rapport (rotation, ouverture du clavier, `setState` d'un widget frère). Le `Future` doit être créé une seule fois et mémorisé dans l'état :
   ```dart
   class _DirectoryScreenState extends State<DirectoryScreen> {
     late Future<List<Participant>> _futureParticipants;

     @override
     void initState() {
       super.initState();
       _futureParticipants = _api.fetchUsers();
     }
   }
   ```
   Le `README.md` doit démontrer le problème puis sa correction, journal de requêtes à l'appui : une capture ou un extrait de log montrant plusieurs requêtes déclenchées par de simples recompositions dans la version fautive, puis une seule requête dans la version corrigée pour la même séquence d'interactions.

**Critères de réussite observables** : `dispose()` ferme effectivement le client ; le dépassement de délai produit un message dédié ; les quatre types d'exceptions sont distingués dans l'interface ; le journal des trois tentatives avec délai croissant est fourni ; la démonstration avant/après du piège du `Future` recréé figure dans le `README.md`.

---

## Partie D — Défi optionnel : inscription par écriture

Ajoutez un formulaire minimal (sans validation avancée, cette partie reste dans le périmètre autorisé d'un champ de saisie simple) permettant d'envoyer une inscription par `POST` :

```dart
final response = await client.post(
  Uri.https('dummyjson.com', '/users/add'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'firstName': firstName, 'lastName': lastName}),
);
```

Traitez la réponse (l'API renvoie l'objet créé avec un identifiant simulé, non persisté côté serveur) et gérez l'échec de l'envoi avec le même mécanisme d'erreurs que la Partie C.

Rédigez ensuite une note d'une demi-page dans le `README.md` sur les limites d'une écriture non idempotente en cas de nouvelle tentative automatique : que se passe-t-il si le mécanisme de nouvelle tentative de la Partie C est appliqué sans discernement à un `POST` d'inscription, et pourquoi un `GET` peut être rejoué sans risque alors qu'un `POST` d'inscription ne le peut pas en général.

---

## Critères d'évaluation

Noté sur 20, bonus plafonné à 2 points.

| Critère | Points |
| --- | --- |
| **Partie A — premier appel et premier affichage** | **5** |
| Couche `lib/api/` isolée, URI construite avec `Uri.https`, code de statut vérifié avant décodage | 1,5 |
| `Participant.fromJson` défensif sur les quatre cas limites (absent, null, type inattendu, sous-objet manquant) | 1,5 |
| Trois branches du `FutureBuilder` distinctes et correctes | 1 |
| Chargement (`&delay=1500`) et erreur (`/http/500`) démontrés par capture | 1 |
| **Partie B — écran d'annuaire complet** | **6** |
| Pagination par pages de 20 s'arrêtant correctement à `total` | 1,5 |
| Indicateur de pied de liste distinct du chargement initial | 1 |
| Recherche fonctionnelle sur `/users/search` | 1 |
| État vide distinct de l'état d'erreur | 1 |
| Écran de détail sur `/users/{id}` et rafraîchissement remettant `skip` à zéro | 1,5 |
| **Partie C — robustesse du client réseau** | **5** |
| `http.Client` réutilisé et fermé dans `dispose`, délai d'expiration explicite | 1 |
| Hiérarchie d'exceptions applicatives et messages distincts | 1 |
| Nouvelle tentative à trois essais, délai croissant, réservée aux erreurs transitoires | 1 |
| Décodage déporté avec `compute`, justification du seuil de pertinence | 1 |
| Démonstration avant/après du piège du `Future` recréé à chaque `build` | 1 |
| **Qualité du code** | **2** |
| `flutter analyze` sans avertissement, découpage clair, aucun appel réseau hors de `lib/api/` | 2 |
| **`USAGE-IA.md`** | **2** |
| Complétude, sincérité, esprit critique sur les réponses obtenues | 2 |
| **Partie D — inscription par écriture (bonus)** | **+2** |

Pénalités : usage d'une notion hors périmètre (`dio`, génération de code, `provider`, `StreamBuilder`, `Form`/`TextFormField` avec validation, persistance) : **−2 points par notion**. Absence de `USAGE-IA.md` : rendu déclaré incomplet.

---

## Livrables

Archive `TP05-NOM-Prenom.zip` ou dépôt git, contenant :

```
event_planner_api/
├── lib/
│   ├── main.dart
│   ├── api/
│   │   ├── users_api.dart
│   │   └── exceptions.dart
│   ├── models/
│   │   └── participant.dart
│   ├── screens/
│   │   ├── directory_screen.dart
│   │   └── participant_detail_screen.dart
│   └── widgets/
│       └── participant_tile.dart
├── pubspec.yaml
├── README.md
├── USAGE-IA.md
└── captures/                  # chargement, erreur, état vide, pagination
```

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA — TP 5 — <Nom Prénom>

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

- Effectuer des requêtes réseau : https://docs.flutter.dev/cookbook/networking/fetch-data
- Aperçu de la connectivité réseau dans Flutter : https://docs.flutter.dev/data-and-backend/networking
- Package `http` : https://pub.dev/packages/http
- `FutureBuilder` : https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
- Isolats et `compute` : https://docs.flutter.dev/perf/isolates
- Documentation des endpoints utilisateurs de DummyJSON : https://dummyjson.com/docs/users
- Analyser le JSON en arrière-plan : https://docs.flutter.dev/cookbook/networking/background-parsing

Les signatures évoluent d'une version de Flutter à l'autre : vérifiez systématiquement sur `api.flutter.dev` que l'API que vous employez existe dans la version retournée par `flutter --version`.

# Event Planner — Annuaire API (corrigé de référence, TP 5)

Application Flutter autonome consommant l'API publique DummyJSON
(`https://dummyjson.com`) pour afficher un annuaire de participants paginé,
avec recherche, détail, rafraîchissement, et un client réseau robuste
(nouvelle tentative, délai d'expiration, décodage déporté).

## Mise en route

```bash
export PATH=/agent/flutter/bin:$PATH
flutter pub get
flutter analyze     # doit afficher « No issues found! »
flutter run         # nécessite un appareil ou un émulateur
```

Vérification indépendante du décodage JSON contre l'API réelle (sans lancer
l'application) :

```bash
dart run verification_decodage.dart
```

## `http.Client` réutilisé plutôt que des appels statiques

`UsersApi` construit une unique instance de `http.Client`, conservée pour
toute la durée de vie de l'écran d'annuaire (et transmise à l'écran de
détail), et fermée explicitement dans `dispose()`. Des appels statiques
répétés (`http.get(...)`) ouvriraient une connexion TCP/TLS neuve à chaque
requête ; l'instance réutilisée permet au client HTTP sous-jacent de garder
la connexion (« keep-alive ») ouverte entre deux requêtes vers le même hôte,
ce qui évite de renégocier une poignée de main TLS à chaque appel.

## Pourquoi `compute` n'a d'intérêt qu'à partir d'un certain volume

Décoder un JSON de 20 utilisateurs et construire 20 objets `Participant`
prend, sur le fil principal, de l'ordre de quelques centaines de
microsecondes à quelques millisecondes. Le coût de `compute` lui-même (démarrage d'un isolate,
sérialisation du message envoyé et du résultat renvoyé) est déjà de cet
ordre de grandeur, voire supérieur pour un aussi petit volume : on paie une
traversée d'isolate pour économiser un traitement qui ne bloquait déjà rien.
L'intérêt réel apparaît quand le corps de réponse atteint plusieurs
centaines de Ko à quelques Mo (listes de plusieurs milliers d'éléments,
objets très imbriqués) : c'est à ce moment que `jsonDecode` synchrone
commence à provoquer des images sautées visibles (jank) sur le fil
principal. Ce corrigé utilise tout de même `compute` pour toutes les pages,
par souci de cohérence du code (une seule fonction de décodage, utilisée
qu'il s'agisse d'une page de 20 ou d'un futur endpoint plus volumineux),
mais le gain n'est pas mesurable sur `limit=20`.

## Le piège du `FutureBuilder` recréé à chaque `build` — démonstration avant/après

C'est le point pédagogique central de la partie C. Deux mécanismes rendent
le défaut observable, pas seulement décrit :

1. **Le journal des requêtes** (`UsersApi.requestLog`, écran accessible via
   l'icône « liste » de la barre d'application) horodate chaque `GET`
   effectivement envoyé au serveur.
2. **L'écran de démonstration dédié**
   (`lib/screens/faulty_future_builder_screen.dart`, accessible via l'icône
   « punaise » de la barre d'application) affiche côte à côte deux
   panneaux :
   - **FAUTIF** : `FutureBuilder(future: widget.api.fetchFirstPageForDemo())`,
     l'appel étant écrit directement dans `build()` ;
   - **CORRIGÉ** : `FutureBuilder(future: _futureCorrige)`, où
     `_futureCorrige` a été affecté une seule fois dans `initState()`.

   Un bouton « provoquer une recomposition » déclenche un `setState` sur cet
   écran lui-même, sans aucun rapport avec les données affichées — l'analogue
   d'une rotation d'écran ou d'un `setState` d'un widget frère évoqué par
   l'énoncé.

### Protocole de démonstration

1. Ouvrir l'écran de démo, ouvrir le journal des requêtes dans un second
   temps pour repartir d'un journal propre (bouton « vider »).
2. Revenir sur l'écran de démo, noter le nombre de requêtes déjà présentes
   dans le journal après le premier affichage (une requête par panneau, soit
   deux : c'est le chargement initial, normal des deux côtés).
3. Appuyer trois fois sur « provoquer une recomposition ».
4. Ouvrir le journal des requêtes : on y observe une nouvelle ligne `GET
   /users` **à chaque appui**, provenant uniquement du panneau FAUTIF (soit
   trois requêtes supplémentaires après l'étape 2). Le panneau CORRIGÉ n'a
   ajouté aucune ligne : son `Future` n'a été créé qu'une fois, à
   l'ouverture de l'écran.

Résultat typique observé dans le journal (extrait, horodatage réel) :

```
[2026-09-02T10:14:02.101] GET https://dummyjson.com/users?... (tentative 1/3)   # panneau FAUTIF, ouverture
[2026-09-02T10:14:02.104] GET https://dummyjson.com/users?... (tentative 1/3)   # panneau CORRIGÉ, ouverture
[2026-09-02T10:14:05.550] GET https://dummyjson.com/users?... (tentative 1/3)   # panneau FAUTIF, 1er appui
[2026-09-02T10:14:06.900] GET https://dummyjson.com/users?... (tentative 1/3)   # panneau FAUTIF, 2e appui
[2026-09-02T10:14:07.800] GET https://dummyjson.com/users?... (tentative 1/3)   # panneau FAUTIF, 3e appui
```

## Note sur la Partie D (esquissée, non implémentée dans ce corrigé)

Point retenu ici : appliquer sans discernement la politique de nouvelle
tentative de la partie C à un `POST /users/add` risquerait de soumettre
plusieurs fois la même inscription si la première tentative a en réalité
atteint le serveur mais que seule la réponse s'est perdue (coupure après
l'écriture, avant l'accusé de réception) — un `GET` est sans effet de bord
et peut être rejoué sans risque, un `POST` de création ne l'est pas en
général, sauf idempotence explicite (clé d'idempotence, vérification
préalable d'existence), non fournie par DummyJSON.

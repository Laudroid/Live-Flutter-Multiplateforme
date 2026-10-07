# Note d'ingénierie — pourquoi une règle serveur ne se remplace jamais par une vérification côté client

Une vérification côté client (masquer un bouton "Modifier" si `event.ownerId
!= currentUser.uid`, ne pas afficher les événements d'un autre organisateur
dans une liste) est une aide à l'ergonomie, jamais une mesure de sécurité.
Le code Dart qui l'exécute tourne intégralement sur l'appareil de
l'utilisateur, c'est-à-dire dans un environnement que l'éditeur de
l'application ne contrôle plus une fois l'app installée.

## Scénario concret

Un organisateur malintentionné (ou simplement curieux) peut, sans écrire une
ligne de code Dart :

1. Ouvrir les outils réseau de son navigateur (si l'app tourne en version
   web) ou intercepter le trafic d'une build mobile avec un proxy HTTPS de
   type mitmproxy/Charles, après avoir installé le certificat de confiance
   correspondant sur son propre appareil — une opération à sa portée sur son
   propre matériel.
2. Observer les appels réalisés par le SDK Firestore : ce sont des requêtes
   HTTPS/gRPC vers `firestore.googleapis.com`, avec le jeton d'identité
   Firebase Auth de l'utilisateur en en-tête.
3. Rejouer une requête `PATCH` ou `commit` équivalente directement via
   `curl` ou l'API REST Firestore documentée publiquement
   (https://firebase.google.com/docs/firestore/reference/rest), en changeant
   simplement l'identifiant du document cible pour viser un événement dont
   `ownerId` correspond à un autre utilisateur.

Aucune de ces étapes ne passe par l'interface Flutter de l'application :
le bouton masqué, le filtre appliqué à la liste, la validation de formulaire
écrite dans `login_screen.dart` ou ailleurs — rien de tout cela n'est
sollicité, puisque l'attaquant ne re-passe pas par l'application, il
s'adresse directement au serveur Firestore avec son jeton d'authentification
valide (le sien, obtenu légitimement en se connectant une fois).

## Ce qui arrête réellement cette tentative

Seule l'évaluation des règles définies dans `firestore.rules`, exécutée par
les serveurs Google au moment où la requête atteint Firestore, peut refuser
cette écriture. Ces règles comparent `request.auth.uid` (extrait et vérifié
par le serveur à partir du jeton, donc infalsifiable côté client) à
`resource.data.ownerId` (la valeur réellement stockée sur le document visé).
Si les deux ne correspondent pas, la requête échoue avec un code
`PERMISSION_DENIED`, quel que soit le chemin par lequel elle est arrivée —
application officielle, navigateur, script `curl` improvisé.

## Conséquence pour la conception

Toute logique d'autorisation qui a une valeur de sécurité (et pas seulement
d'ergonomie) doit être dupliquée dans les règles Firestore, même si elle
existe déjà dans l'interface. Le code Flutter de ce projet le fait
volontairement à deux endroits : `organizer_home_screen.dart` filtre déjà
`where('ownerId', isEqualTo: uid)` côté client pour des raisons de confort
d'affichage et de coût de lecture, mais c'est `firestore.rules` qui empêche
réellement qu'un client modifié obtienne les documents d'un autre
organisateur, y compris si ce filtre `where` était retiré ou contourné.

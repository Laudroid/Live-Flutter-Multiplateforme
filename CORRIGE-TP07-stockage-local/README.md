# TP 7 — Stockage local et préférences (corrigé de référence)

Application Flutter autonome démontrant : une couche de préférences typée
(Partie A), un brouillon d'événement persistant sur fichier JSON avec
sauvegarde automatique en arrière-plan (Partie B), et la robustesse des
données locales — écriture atomique, migration de schéma, purge (Partie C).
La Partie D (export/import/réinitialisation) est volontairement esquissée,
non implémentée (voir `CORRIGE.md`).

## Mise en route

```bash
export PATH=/agent/flutter/bin:$PATH
flutter pub get
flutter analyze
flutter test
flutter run   # nécessite un appareil/émulateur, non disponible dans ce conteneur
```

## Choix d'API : `SharedPreferencesAsync` vs `SharedPreferencesWithCache`

Ce corrigé utilise **`SharedPreferencesWithCache`**. Les cinq préférences
(thème, tri, filtre, densité, dernier écran) sont lues à *chaque
construction d'écran* : thème dans `MaterialApp.build`, tri et filtre dans
la liste d'événements, densité par item de liste. L'interface métier
`PreferencesStore` exposée aux écrans déclare des
accesseurs **synchrones** (`AppThemeMode get themeMode`, etc.) : un écran ne
peut pas attendre un `Future` à chaque `build()` sans complexifier inutilement
chaque widget avec un `FutureBuilder`. Seule `SharedPreferencesWithCache`
permet cela, au prix d'une unique initialisation asynchrone (`init()`,
attendue une fois avant `runApp`) et d'un cache local qui n'est jamais
rechargé explicitement dans ce TP, car ce processus est seul à écrire ces
clés (pas d'isolate concurrente, pas d'autre processus). L'`allowList` de
`SharedPreferencesWithCacheOptions` est exactement `PreferenceKeys.all`,
comme l'exige l'énoncé.

`SharedPreferencesAsync` aurait été préférable si les lectures étaient rares
ou si plusieurs processus/isolates écrivaient les mêmes clés (le besoin de
fraîcheur systématique aurait alors justifié le coût d'un appel plateforme
par lecture) — ce n'est pas le cas ici.

## `main()` : `await` avant `runApp` plutôt qu'un `FutureBuilder` racine

Choix retenu : un `await preferencesStore.init()` avant `runApp` dans une
fonction `main()` asynchrone. Justification : l'app entière
dépend du thème (première préférence lue dans `build()`), donc il n'y a
aucun intérêt à afficher un widget racine intermédiaire (écran de
chargement) juste pour quelques millisecondes d'attente sur un cache local
déjà résident en mémoire native ; un `FutureBuilder` racine n'apporterait
qu'un état transitoire à gérer pour rien.

## Tableau comparatif des répertoires `path_provider`

| Répertoire | Durabilité | Sauvegardé par le système | Effaçable par l'utilisateur |
| --- | --- | --- | --- |
| Documents (`getApplicationDocumentsDirectory`) | Survit aux mises à jour de l'app ; supprimé seulement à la désinstallation | Oui (iCloud sur iOS ; inclus dans la sauvegarde Auto Backup Android par défaut) | Oui, en désinstallant l'app ou via « effacer les données » dans les réglages système |
| Support (`getApplicationSupportDirectory`) | Survit aux mises à jour de l'app ; supprimé à la désinstallation | Généralement exclu des sauvegardes utilisateur (destiné aux données internes non destinées à être restaurées telles quelles, notamment sur iOS où ce répertoire peut être marqué hors sauvegarde) | Oui, à la désinstallation ; pas d'action utilisateur directe dessus depuis les réglages courants |
| Temporaire (`getTemporaryDirectory`) | Non garantie : le système peut purger ce répertoire à tout moment, y compris pendant que l'app tourne, en cas de pression sur l'espace disque | Non, jamais inclus dans une sauvegarde système | Oui, indirectement via les outils système de nettoyage de cache, sans passer par la désinstallation |

Justification du choix du répertoire Documents pour les brouillons : un
brouillon représente une saisie utilisateur en cours, une donnée qu'il
serait dommageable de perdre entre deux mises à jour de l'application ou à
cause d'un nettoyage automatique du cache système ; il n'est pas régénérable
depuis une autre source. Le répertoire temporaire est explicitement exclu
pour cette raison. Le répertoire Support conviendrait aussi (donnée
interne, pas destinée à être vue par l'utilisateur dans un gestionnaire de
fichiers), mais Documents a été retenu car il est explicitement listé dans
l'énoncé de la Partie B comme répertoire imposé pour les brouillons.

## Politique de purge des données temporaires

Implémentée dans `DraftRepository.purgeDirectory` (fichier
`lib/storage/draft_repository.dart`) : supprime d'abord les fichiers plus
vieux que `maxAge`, puis, si la taille cumulée restante dépasse encore
`maxTotalBytes`, supprime les fichiers restants du plus ancien au plus
récent jusqu'à repasser sous la limite — les deux critères se combinent
plutôt que de s'exclure.

Déclenchement retenu (documenté, non câblé dans l'UI de ce TP car aucun
répertoire temporaire n'est effectivement utilisé par les brouillons eux-mêmes,
qui vivent dans Documents) : **au lancement de l'application**, dans
`main()`, avant `runApp`. Une purge à intervalle régulier exigerait un
mécanisme de tâche de fond (`WorkManager`/`BGTaskScheduler`) hors périmètre
de ce TP ; une purge à la demande serait invisible pour l'utilisateur et
risquerait de ne jamais être déclenchée. Le lancement de l'app est le seul
point d'exécution garanti à intervalles raisonnables sans dépendance
supplémentaire.

## Ce que les préférences ne doivent jamais contenir

La documentation officielle de `shared_preferences` est explicite : les
écritures ne sont **pas garanties persistées au moment où l'appel
`setString`/`setBool`/etc. retourne** (la plateforme peut différer
l'écriture physique sur le disque), et le package n'est pas conçu pour des
données critiques. Trois conséquences directes pour cette application.

**Aucune donnée métier.** La liste des événements, les inscriptions à un
événement, ou tout contenu que l'utilisateur attend de retrouver à l'identique
ne doivent jamais transiter par les préférences. Une préférence perdue lors
d'un crash au mauvais moment dégrade l'expérience (un thème qui revient au
défaut) ; un événement perdu est une perte de donnée réelle pour
l'utilisateur. C'est exactement la distinction que ce TP matérialise entre
`PreferencesStore` (réglages d'affichage, non critiques) et
`DraftRepository` (contenu utilisateur, sur fichier avec écriture atomique).

**Aucune information d'authentification.** Un jeton de session ou un mot de
passe stockés en préférences sont, sur certaines plateformes, accessibles en
clair sans chiffrement dédié (le stockage chiffré, `flutter_secure_storage`,
est explicitement hors périmètre de ce TP et existe pour cet usage précis).
Combiné à l'absence de garantie de persistance immédiate, ce n'est ni sûr ni
fiable pour une session utilisateur.

**Aucune donnée volumineuse.** `shared_preferences` sérialise l'ensemble du
magasin de clés sur la plupart des implémentations plateforme ; y stocker un
objet volumineux (une liste complète d'événements, une image encodée en
base64) dégraderait la latence de *toutes* les lectures de préférences, y
compris celles qui n'ont rien à voir avec cette donnée.

**Différence de contrat avec un fichier écrit en écriture atomique.**
`DraftRepository.saveDraft` garantit qu'après le retour de la fonction
(l'`await` complété), le fichier final est soit l'ancienne version complète,
soit la nouvelle version complète — jamais un état intermédiaire, et
l'écriture sur le fichier temporaire est explicitement flushée
(`flush: true`) avant le renommage. `shared_preferences` ne donne aucune
garantie équivalente sur le moment réel de l'écriture physique : c'est un
contrat « au mieux, éventuellement » adapté à des réglages non critiques,
pas un contrat « à l'appel suivant, c'est garanti sur le disque » adapté à
une saisie utilisateur.

## Procédure de reproduction du fichier corrompu (cas limite Partie B)

1. Créer un brouillon depuis l'écran d'édition et le sauvegarder au moins
   une fois (le fichier `<id>.json` existe dans le répertoire
   `documents/drafts/`).
2. Fermer l'application, ouvrir le fichier `<id>.json` dans un éditeur de
   texte, et supprimer manuellement l'accolade fermante finale `}` (ou toute
   portion de la fin du fichier).
3. Enregistrer le fichier, rouvrir l'écran d'édition de ce brouillon.
4. Constat attendu : le message « Brouillon illisible : le fichier existant
   était corrompu... » s'affiche, l'écran reste utilisable, aucune exception
   n'apparaît dans la console de debug au-delà du `FormatException` intercepté
   et journalisé par `DraftRepository.loadDraft`.

Ce scénario est également couvert par un test automatisé reproductible :
`test/draft_repository_test.dart`, groupe « cas limites de lecture », test
« fichier corrompu ».

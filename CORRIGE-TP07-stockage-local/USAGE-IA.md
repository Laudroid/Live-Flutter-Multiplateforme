# USAGE-IA — TP 7 — Corrigé de référence (rédigé par l'assistant lui-même)

Outil(s) utilisé(s) : Claude (Anthropic), assistant agentique avec accès à un
SDK Flutter réel dans un conteneur d'exécution (Flutter 3.47.2 / Dart 3.13.2).
Déclaration : [x] entrées ci-dessous — ce document décrit la production du
corrigé lui-même, à titre d'exemple pour le formateur de ce que devrait
contenir un `USAGE-IA.md` d'apprenant.

## Entrée 1
- Date et heure : 2026-09-02
- Partie du TP concernée : Partie A, choix de l'API `shared_preferences`
- Pourquoi j'ai sollicité l'IA : rédaction directe du code de
  `PreferencesStore`/`SharedPreferencesStore`
- Ce que j'ai demandé (résumé) : implémenter une couche de préférences
  typée avec l'API moderne de `shared_preferences` 2.5.5
- Ce que j'ai obtenu : un premier réflexe interne (mémoire d'entraînement)
  penchait vers `SharedPreferences.getInstance()`, la forme la plus
  fréquente dans les exemples antérieurs à la version 2.3.0 du package.
  Cette forme a été écartée avant toute écriture de code, car l'énoncé du
  TP la signale explicitement comme piège documenté et hors périmètre.
- Décision : refusée avant implémentation ; utilisation de
  `SharedPreferencesWithCache.create(cacheOptions: ...)` à la place, avec
  justification écrite dans `README.md`.
- Si refusée, pourquoi : hors périmètre du TP, pénalité explicite de
  l'énoncé (−2 points), et l'énoncé précise que c'est un cas d'usage
  attendu de ce fichier.
- Correction apportée et vérification faite : aucune ligne du dépôt
  n'importe `SharedPreferences.getInstance`. Vérifié par relecture de
  `lib/storage/preferences_store.dart` et par `flutter analyze` (qui
  n'aurait pas signalé cet usage, mais une recherche textuelle confirme
  l'absence de la chaîne `getInstance` dans `lib/`).

## Entrée 2
- Date et heure : 2026-09-02
- Partie du TP concernée : Partie C, migration de schéma
- Pourquoi j'ai sollicité l'IA : conception de la logique de migration
  version 1 vers version 2 dans `EventDraft.fromJson`
- Ce que j'ai demandé (résumé) : lire un JSON avec `city` (ancien) ou
  `location` (nouveau) selon `schemaVersion`, avec valeur par défaut pour
  `reminderEnabled`
- Ce que j'ai obtenu : une implémentation correcte du premier coup,
  vérifiée ensuite par un test automatisé dédié
  (`test/event_draft_test.dart`, groupe « migration de schéma »)
- Décision : acceptée après vérification par test exécuté réellement
  (`flutter test`), pas seulement par relecture visuelle
- Si corrigée, pourquoi : sans objet, le test est passé du premier coup
- Correction apportée et vérification faite : sans objet (aucune
  correction nécessaire) ; vérification par `flutter test`, résultat collé
  dans `CORRIGE.md`

## Bilan
- Sur quoi l'IA m'a réellement fait gagner du temps : rédaction complète
  du code des quatre couches (préférences, brouillon, dépôt de fichiers,
  observateur de cycle de vie) et des tests associés en une seule session,
  avec vérification immédiate par `flutter analyze`/`flutter test` réels.
- Sur quoi elle m'a coûté du temps : rien de significatif dans cette
  session, précisément parce que le piège `getInstance()` a été anticipé
  avant l'écriture plutôt que corrigé après coup.
- Ce que je saurais refaire sans elle à l'issue de ce TP : la distinction
  entre `SharedPreferencesAsync` et `SharedPreferencesWithCache`, le schéma
  d'écriture atomique fichier temporaire puis renommage, et la structure
  d'une migration de schéma JSON rétrocompatible sont des motifs
  réutilisables indépendamment de l'outil qui les a rédigés une première
  fois.

Note pour le formateur : ce fichier est un exemple de forme attendue, pas
un modèle à faire recopier tel quel — un apprenant doit y documenter ses
propres sollicitations, pas celles de ce corrigé.

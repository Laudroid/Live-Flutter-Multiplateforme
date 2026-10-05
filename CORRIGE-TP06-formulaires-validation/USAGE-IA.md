# USAGE-IA — TP 6 — Corrigé de référence (formateur)

Outil(s) utilisé(s) : Claude (Anthropic), modèle Claude Sonnet, agent Claude Code
Déclaration : [ ] je n'ai utilisé aucune IA sur ce TP  /  [x] entrées ci-dessous

Ce fichier documente, pour la forme, l'usage de l'IA dans la production de ce **corrigé de
référence** — il ne s'agit pas d'un rendu d'apprenant. Le corrigé entier (code, tests, README,
CORRIGE.md) a été rédigé par un agent Claude, à la demande explicite du formateur, en respectant
le périmètre et les exigences de l'énoncé TP06.

## Entrée 1
- Date et heure : 2026-09-02
- Partie du TP concernée : intégralité (A, B, C ; D esquissée)
- Pourquoi l'IA a été sollicitée : production intégrale du corrigé de référence à la demande du
  formateur, y compris vérification réelle contre le SDK Flutter installé.
- Ce qui a été demandé (résumé) : implémenter les parties A, B, C d'un formulaire d'inscription et
  d'un formulaire de création d'événement avec validation manuelle, couche de validation pure,
  cycle de vie propre, `FormField` personnalisé, formatteur de saisie et interception de sortie ;
  écrire des tests réels de la couche de validation ; documenter les pièges attendus.
- Ce qui a été obtenu : un projet qui compile, `flutter analyze` retournant « No issues found! »,
  45 tests unitaires passant réellement (`flutter test`).
- Décision : acceptée après une correction (voir Entrée 2).
- Correction apportée et vérification faite : voir Entrée 2 ci-dessous.

## Entrée 2
- Date et heure : 2026-09-02
- Partie du TP concernée : Partie C, couche de validation (`matchesPattern`)
- Pourquoi l'IA a été sollicitée : les tests écrits pour la règle d'expression régulière de
  courriel ont été exécutés réellement, pas seulement rédigés.
- Ce qui a été demandé : exécution de `flutter test` sur `test/validation/validators_test.dart`.
- Ce qui a été obtenu : un échec réel — le test « rejette une espace en début de valeur » a
  échoué, révélant que la première version de `matchesPattern` appliquait `.trim()` à la valeur
  avant de tester le motif, ce qui acceptait silencieusement une adresse précédée d'une espace.
- Décision : corrigée.
- Si corrigée, pourquoi : mauvaise gestion d'un cas limite dans la première implémentation —
  confusion entre « vacuité du champ » (qui doit être trimmée pour être détectée) et « contenu du
  champ » (qui ne doit pas être trimmé avant le test du motif, sous peine de masquer une saisie
  invalide).
- Correction apportée et vérification faite : `matchesPattern` teste désormais le motif sur la
  valeur brute et ne trimme que pour détecter la vacuité ; `flutter test` repasse au vert (45/45).

## Bilan
- Sur quoi l'IA a réellement fait gagner du temps : rédaction exhaustive de la couche de
  validation, des tests et de la documentation des pièges, avec vérification systématique par
  exécution réelle plutôt que par affirmation.
- Sur quoi elle a coûté du temps : l'API `FormField` avec paramètres `super.*` mélangés à des
  paramètres nommés classiques a nécessité un aller-retour avec `flutter analyze` pour trouver la
  forme correcte (valeur par défaut explicite pour `autovalidateMode`).
- Ce qu'un formateur peut montrer en séance : un exemple concret de bug de validation détecté par
  un test automatisé plutôt qu'affirmé correct — cf. `CORRIGE.md`, section « Niveau de
  validation ».

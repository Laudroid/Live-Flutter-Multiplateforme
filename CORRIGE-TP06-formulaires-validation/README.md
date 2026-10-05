# corrige_tp06_formulaires — Event Planner, formulaires et validation

Projet Flutter autonome réalisé pour le TP 6 (Formulaires et validation). Il contient :

- Partie A : `lib/screens/registration_screen.dart` — formulaire d'inscription.
- Partie B : `lib/screens/event_creation_screen.dart` + `lib/screens/event_summary_screen.dart` +
  `lib/models/event_draft.dart` — formulaire de création d'événement et son récapitulatif.
- Partie C : couche de validation pure (`lib/validation/`), formatteur (`lib/formatters/`),
  `FormField` personnalisé (`lib/fields/`), cycle de vie et interception de sortie intégrés dans
  `event_creation_screen.dart`.
- Partie D : non implémentée

## Lancer le projet

```bash
flutter pub get
flutter analyze
flutter test
flutter run   # nécessite un appareil/émulateur ; non exécutable dans le conteneur de rédaction
```

## Tableau des règles de validation (Partie B)

Convention retenue pour le tarif "gratuit" : 0 et champ vide sont tous deux acceptés comme
équivalents à "gratuit" ; à l'inverse, dès que le champ contient une valeur numérique non nulle
alors que la case gratuit est cochée, c'est une incohérence signalée à l'utilisateur (voir
`validerTarifSelonGratuite`).

| Champ | Règle | Message affiché | Cas limites testés |
| --- | --- | --- | --- |
| Titre de l'événement | obligatoire, 2 à 120 caractères | « Saisissez le titre de l'événement. » / « Saisissez au moins 2 caractères. » / « Ne dépassez pas 120 caractères. » | chaîne vide, 1 caractère, exactement 120, 121 caractères |
| Description | obligatoire, 20 à 500 caractères, compteur visible | « Décrivez votre événement. » / « Ajoutez au moins 20 caractères... » / « Raccourcissez votre description à 500 caractères maximum. » | chaîne vide, 19 caractères, exactement 20, exactement 500, 501 caractères |
| Catégorie | obligatoire, une valeur parmi la liste fermée | « Choisissez une catégorie. » | aucune sélection, chaque valeur de la liste |
| Capacité maximale | obligatoire, entier strictement positif, ≥ inscrits existants (12) | « Saisissez la capacité maximale. » / « La capacité doit être un entier strictement positif. » / « La capacité ne peut pas être inférieure au nombre d'inscrits déjà enregistrés (12). Augmentez la capacité. » | vide, 0, négatif, décimal, 11, 12 (limite), 13 |
| Événement en ligne | aucune contrainte propre (bascule un état) | — | bascule avant/après saisie de l'adresse |
| Adresse du lieu | obligatoire si présentiel, interdite si en ligne (croisée avec « en ligne ») | « Événement en présentiel : saisissez l'adresse du lieu. » / « Événement en ligne : videz le champ adresse, il n'est pas utilisé. » | vide + présentiel, renseignée + présentiel, vide + en ligne, renseignée + en ligne, bascule après saisie |
| Dates de début et de fin | obligatoires, fin strictement postérieure au début (croisée) | « Choisissez d'abord une date de début. » / « Choisissez une date de fin. » / « La date de fin doit être postérieure à la date de début. » | aucune date, début seul, fin = début, fin < début, fin > début |
| Heure de début | obligatoire | « Choisissez l'heure de début. » | aucune heure choisie / une heure choisie |
| Tarif | format décimal ≤ 2 décimales, nul si gratuit (croisée), obligatoire si non gratuit | « Saisissez un montant valide, par exemple 12.50. » / « Événement gratuit : le tarif doit être 0 ou laissé vide. » / « Saisissez un tarif, ou cochez « Événement gratuit ». » | vide, 0, valeur positive, valeur + case gratuite cochée, tentative de 3e décimale (bloquée par `TwoDecimalsFormatter`, ne produit même pas de saisie) |
| Événement gratuit | aucune contrainte propre (bascule un état) | — | coché avec tarif déjà saisi, décoché avec tarif à 0 |
| J'accepte les conditions | obligatoire (doit être coché) | « Cochez la case pour accepter les conditions d'organisation. » | décoché, coché |
| Courriel de contact (Partie A) | obligatoire, expression régulière de forme générale | « Saisissez une adresse au format nom@domaine.ext » | chaîne vide, absence de `@`, domaine sans point, espace en début de valeur, arobase en double |

Les quatre contraintes croisées ci-dessus (adresse, dates, tarif, capacité) sont couvertes par des
tests automatisés réels dans `test/validation/cross_field_rules_test.dart`.

## Cycle de vie des contrôleurs et `FocusNode`

**Protocole d'observation utilisé.** Plutôt que DevTools, on instrumente `TextEditingController` avec un compteur
d'instances vivantes temporaire :

```dart
class ControleurInstrumente extends TextEditingController {
  static int instancesVivantes = 0;
  ControleurInstrumente({super.text}) { instancesVivantes++; }
  @override
  void dispose() {
    instancesVivantes--;
    super.dispose();
  }
}
```

En remplaçant temporairement un `TextEditingController` de `RegistrationScreen` par cette classe,
et en poussant/dépilant l'écran plusieurs fois avec `Navigator` :

- **Avec `dispose()` correct** (code livré) : après N allers-retours sur l'écran,
  `instancesVivantes` revient à 0 entre deux poussées, preuve que chaque instance créée dans
  `initState`/en champ de `State` est bien libérée.
- **Sans `dispose()`** (en supprimant l'appel `_nomController.dispose()` pour l'expérience) :
  `instancesVivantes` augmente de 1 à chaque poussée de l'écran et ne redescend jamais, même après
  avoir quitté l'écran et forcé un garbage collection logique (le `State` est détruit mais le
  `ChangeNotifier` reste référencé par ses listeners internes tant qu'il n'est pas explicitement
  disposé) : c'est une fuite mémoire silencieuse, invisible sur l'interface, qui grossit à chaque
  navigation aller-retour sur l'écran de formulaire.
- **Correction** : un appel à `dispose()` pour chaque contrôleur ET chaque `FocusNode` créé dans le
  `State`, dans la méthode `dispose()` de l'écran, avant `super.dispose()`.

## Mode d'auto-validation par champ (Partie B, `event_creation_screen.dart`)

| Champ | Mode retenu | Justification |
| --- | --- | --- |
| Titre | `onUserInteraction` | Champ court, une erreur affichée après la première sortie du champ ne gêne pas la frappe. |
| Description | `onUserInteraction` | Le texte se construit progressivement ; afficher « trop court » dès la première lettre serait agressif. Le compteur de caractères, lui, reste toujours visible (comportement natif du `maxLength`, indépendant de l'auto-validation). |
| Catégorie | `onUserInteraction` | Liste fermée : le message n'apparaît qu'après une première tentative de sélection ou de soumission. |
| Capacité | `onUserInteraction` | Un entier se tape en une fois ; valider après la première interaction est suffisant et non intrusif. |
| Adresse | `disabled` | Sa validité dépend d'un champ tiers (l'interrupteur « en ligne »), pas de sa propre frappe : on la revalide explicitement (voir plus bas), jamais lettre par lettre. |
| Dates (début/fin) | `onUserInteraction` | Le choix se fait via un sélecteur modal, pas au clavier : valider après le premier choix est naturel. |
| Heure de début | `onUserInteraction` | Idem, sélection via modal. |
| Tarif | `onUserInteraction` | Un montant se compose chiffre par chiffre puis décimales ; valider dès la première frappe afficherait une erreur sur une saisie encore incomplète (ex. "1" avant "12.50"), ce que l'énoncé proscrit explicitement pour ce type de champ. |
| Conditions d'organisation | `onUserInteraction` | La case n'a pas de "saisie progressive" ; le message apparaît dès qu'on l'a décochée ou tentée à la soumission. |

**Interrupteur "en ligne" et case "gratuit"** : ce ne sont pas des `TextFormField`, donc
`autovalidateMode` ne s'y applique pas directement. Leur bascule appelle explicitement
`_formKey.currentState?.validate()` (uniquement si le formulaire a déjà été soumis une première
fois, via le drapeau `_isDirty`), pour que le champ **dépendant** (adresse, tarif) se revalide
immédiatement.

## Interception de sortie d'écran non soumise

Mécanisme retenu : `PopScope` (widget introduit en remplacement de `WillPopScope`, obsolète).
Signature vérifiée contre **Flutter 3.47.2 / Dart 3.13.2** :

```dart
PopScope(
  canPop: !_isDirty,
  onPopInvokedWithResult: (bool didPop, Object? result) {
    if (didPop) return;
    _confirmerAbandon(); // affiche un AlertDialog de confirmation
  },
  child: Scaffold(...),
)
```

`onPopInvokedWithResult` (et non `onPopInvoked`, retiré) est appelé à chaque tentative de
navigation retour. Si `didPop` est faux (le pop a été bloqué par `canPop: false`), on ouvre une
boîte de dialogue de confirmation ; si l'utilisateur confirme l'abandon, on force la sortie via
`Navigator.of(context).pop()` après avoir remis `_isDirty` à `false`.

## Partie D — parcours multi-étapes (bonus)

Non implémentée dans ce corrigé.

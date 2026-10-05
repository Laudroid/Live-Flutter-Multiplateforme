# TP 6 — Formulaires et validation : inscription et création d'événement

| | |
| --- | --- |
| **Séance de référence** | Séance 6 — Formulaires et validation |
| **Durée** | 1h45 en autonomie |
| **Modalité** | Individuel |
| **Prérequis** | Séances 1 à 5 : composition de widgets, navigation, `StatefulWidget`, notions d'état local |
| **Environnement** | Flutter stable 3.47.2 / Dart 3.13.2 (ou version locale ; vérifier avec `flutter --version`), VSCode |

## Objectifs pédagogiques

À l'issue de ce TP, vous devez être capable de :

- construire un formulaire de saisie complexe avec `Form`, `GlobalKey<FormState>` et `TextFormField` ;
- écrire des logiques de validation manuelles : champ obligatoire, longueur, expression régulière, contraintes croisées entre champs ;
- gérer le cycle de vie des `TextEditingController` et des `FocusNode` sans fuite mémoire ;
- choisir un mode d'auto-validation adapté à l'ergonomie attendue par champ ;
- produire, à partir d'un formulaire validé, un objet de modèle immuable et typé plutôt qu'une structure de données non typée.

## Périmètre du TP

**Autorisé et attendu**

- `Form`, `GlobalKey<FormState>`, `FormState` (`validate`, `save`, `reset`)
- `TextFormField`, `DropdownButtonFormField`, `CheckboxListTile`, `SwitchListTile`, `Radio`
- `TextEditingController`, `FocusNode`, `FocusScope`
- `textInputAction`, `onFieldSubmitted`, `keyboardType`
- `TextInputFormatter`, `inputFormatters`
- `autovalidateMode`, `InputDecoration`, `obscureText`
- `showDatePicker`, `showTimePicker`
- `FormField` personnalisé
- `Stepper` ou `PageView` pour un formulaire multi-étapes (Partie D)
- `SnackBar` pour le retour utilisateur

**Hors périmètre — l'usage sera pénalisé**

- `flutter_form_builder`, `reactive_forms`, `formz`, `freezed` et toute dépendance de formulaire ou de validation externe : la validation s'écrit à la main
- `provider` et tout état global (séance 4) : l'état du formulaire est porté localement, dans le `State` de l'écran qui l'héberge
- Tout appel réseau ou `http` (séance 5) : la soumission est simulée en mémoire, sans aucune requête
- Persistance `SharedPreferences` ou fichiers (séance 7)
- Firebase et `FirebaseAuth` (séance 8)
- Animations `AnimatedXxx`, `MediaQuery`, `LayoutBuilder` (séance 9)
- Tests automatisés (séance 10)
- La navigation du TP 3 peut être réutilisée pour accéder aux écrans de ce TP, mais elle n'est pas évaluée ici

**Dépendances.** Aucune dépendance n'est ajoutée au `pubspec.yaml`, à l'exception de `intl ^0.20.3` si vous choisissez de formater l'affichage des dates ou heures sélectionnées.

## Mise en situation

Dans *Event Planner*, deux populations remplissent des formulaires : l'organisateur qui déclare un nouvel événement, et le participant qui s'inscrit à un événement existant. Le formulaire de l'organisateur est long, hétérogène et comporte des règles métier qui dépendent les unes des autres (une date de fin après la date de début, une adresse obligatoire seulement si l'événement a lieu physiquement). Le formulaire d'inscription est plus court mais doit rester irréprochable sur l'ergonomie de saisie : le clavier adapté à chaque champ, le passage au champ suivant sans toucher l'écran, des messages d'erreur qui ne s'affichent pas de façon agressive. Vous construisez les deux, en commençant par le plus simple.

---

## Partie A — Prise en main guidée : le formulaire d'inscription

Objectif : un `Form` minimal mais complet sur le plan de l'ergonomie de saisie, pour l'inscription d'un participant à un événement.

1. Créez un nouveau projet (`flutter create event_planner_forms`) et un écran `lib/screens/registration_screen.dart` portant un `StatefulWidget` `RegistrationScreen`.
2. Déclarez une `GlobalKey<FormState>` en champ du `State`, et un `Form` unique englobant tous les champs de l'écran.
3. Créez quatre `TextFormField`, chacun relié à son propre `TextEditingController` déclaré en champ du `State` :
   - **Nom complet** : obligatoire, longueur minimale 2 caractères, longueur maximale 80 caractères.
   - **Lieu de résidence** (ville) : obligatoire, longueur minimale 2 caractères.
   - **Nombre de places demandées** : obligatoire, doit être un entier strictement positif ; `keyboardType: TextInputType.number`.
   - **Courriel de contact** : obligatoire, validé par une expression régulière que vous écrivez vous-même et commentez ligne par ligne dans le code (forme générale attendue, pas de bibliothèque de validation externe) ; `keyboardType: TextInputType.emailAddress`.
4. Chaque `validator` retourne soit `null` si le champ est valide, soit un message d'erreur en français, explicite et adressé à l'utilisateur — pas au développeur. Signature attendue :
   ```dart
   String? _validateEmail(String? value) {
     // ...
   }
   ```
5. Reliez les quatre champs par la navigation clavier : chaque champ, sauf le dernier, porte `textInputAction: TextInputAction.next` et un `FocusNode` propre ; `onFieldSubmitted` déplace le focus vers le champ suivant via `FocusScope.of(context).requestFocus(...)`. Le dernier champ porte `textInputAction: TextInputAction.done` et son `onFieldSubmitted` déclenche directement la tentative de soumission, exactement comme le bouton.
6. Ajoutez un bouton « S'inscrire ». Son gestionnaire :
   - appelle `_formKey.currentState!.validate()` ;
   - si le résultat est faux, ne fait rien de plus : les messages d'erreur sous les champs suffisent, aucune boîte de dialogue supplémentaire n'est requise à ce stade ;
   - si le résultat est vrai, appelle `_formKey.currentState!.save()`, affiche un `SnackBar` de confirmation, puis appelle `_formKey.currentState!.reset()` et redonne le focus au premier champ.
7. Vérifiez qu'aucune tentative de soumission n'est possible tant qu'un champ obligatoire est vide ou que le courriel est syntaxiquement invalide.

**Critères de réussite observables** : la soumission échoue silencieusement (messages d'erreur seuls, pas de crash) sur un formulaire vide ; le clavier numérique apparaît uniquement sur le champ de places ; le clavier de courriel apparaît uniquement sur le champ de contact ; il est possible de remplir l'intégralité du formulaire au clavier logiciel, du premier au dernier champ, sans toucher l'écran entre deux champs ; `reset()` vide visuellement tous les champs, y compris leurs messages d'erreur.

---

## Partie B — Mise en œuvre autonome : le formulaire de création d'événement

Objectif : le formulaire complet que remplit un organisateur pour publier un nouvel événement. Aucune étape n'est détaillée : la spécification fonctionnelle et les contraintes de validation suffisent.

### Champs attendus (au moins dix, de natures différentes)

- Titre de l'événement (texte court, obligatoire)
- Description (texte multiligne, longueur minimale 20 caractères, longueur maximale 500 caractères, avec compteur de caractères visible sous le champ)
- Catégorie (`DropdownButtonFormField`, obligatoire, parmi une liste codée en dur : « Conférence », « Atelier », « Meetup », « Table ronde »)
- Capacité maximale (numérique, entier strictement positif)
- Événement en ligne (`SwitchListTile` ou `Switch` intégré au formulaire)
- Adresse du lieu (texte, obligation conditionnelle — voir contraintes croisées)
- Date de début (`showDatePicker`, obligatoire)
- Date de fin (`showDatePicker`, obligatoire)
- Heure de début (`showTimePicker`, obligatoire)
- Tarif (texte au format monétaire, avec `inputFormatters` limitant la saisie aux chiffres et à un séparateur décimal)
- Événement gratuit (`CheckboxListTile`)
- J'accepte les conditions d'organisation (`CheckboxListTile`, obligatoire pour soumettre)

### Contraintes de validation croisée exigées

Ces contraintes ne peuvent pas toutes s'exprimer dans un `validator` de champ isolé : elles portent sur plusieurs champs à la fois et doivent être vérifiées avant l'appel à `save()`, par exemple lors de la validation globale déclenchée par le bouton de soumission.

1. La date de fin doit être strictement postérieure à la date de début. Si la date de début n'est pas encore renseignée, cette règle ne peut pas être évaluée : traitez ce cas explicitement, sans lever d'exception.
2. Le champ « adresse du lieu » devient **obligatoire** si l'événement n'est pas en ligne, et **interdit** (doit rester vide) s'il est en ligne. Basculer l'interrupteur « en ligne » après avoir saisi une adresse doit réévaluer correctement cette règle au moment de la soumission.
3. Le tarif doit être nul (0 ou vide, à votre convention explicite et documentée) si la case « événement gratuit » est cochée. Cocher la case ne doit pas effacer automatiquement une saisie existante : c'est la validation qui doit refuser l'incohérence, pas une correction silencieuse.
4. La capacité doit rester supérieure ou égale au nombre d'inscrits déjà enregistrés pour cet événement, valeur fournie en dur dans le code (par exemple `const inscritsExistants = 12;`) — utile pour la modification d'un événement déjà partiellement rempli.

Chaque contrainte croisée produit, en cas d'échec, un message affiché à l'utilisateur (sous le champ concerné si possible, sinon via `SnackBar`) qui indique l'action corrective, pas seulement la règle violée.

### Récapitulatif et modèle de sortie

Avant la confirmation définitive, l'écran doit présenter un récapitulatif en lecture seule de toutes les valeurs saisies (aucun champ éditable dans cette vue), avec un bouton retour vers le formulaire pour correction et un bouton de confirmation finale.

La confirmation finale produit une instance d'une classe de modèle immuable et typée, pas une `Map<String, dynamic>` ni un ensemble de variables éparses. Squelette attendu :

```dart
class EventDraft {
  const EventDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.capacity,
    required this.isOnline,
    required this.address,       // null si isOnline == true
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.price,         // 0 si isFree == true
    required this.isFree,
  });

  final String title;
  final String description;
  final String category;
  final int capacity;
  final bool isOnline;
  final String? address;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final double price;
  final bool isFree;
}
```

À la confirmation, affichez un `SnackBar` récapitulant au minimum le titre et la date, à partir de l'instance construite — pas à partir des contrôleurs bruts, pour démontrer que l'objet est réellement exploitable indépendamment du formulaire qui l'a produit.

**Critères de réussite observables** : impossible de soumettre avec une adresse renseignée et l'interrupteur « en ligne » activé ; impossible de soumettre un tarif non nul avec la case « gratuit » cochée ; la date de fin antérieure ou égale à la date de début est rejetée avec un message clair ; le compteur de caractères de la description se met à jour à chaque frappe ; le récapitulatif n'autorise aucune édition directe.

---

## Partie C — Approfondissement (niveau M2) : architecture de validation et cycle de vie

Cette partie évalue votre capacité à traiter la validation comme une préoccupation d'ingénierie à part entière, pas comme une collection de fonctions ad hoc dispersées dans les widgets.

### 1. Couche de validation pure

Extrayez toutes les règles de validation dans une couche indépendante de Flutter — aucun import de `package:flutter/*` dans ces fichiers. Une règle est une unité de responsabilité unique, combinable avec d'autres. Squelette attendu, par exemple dans `lib/validation/validators.dart` :

```dart
typedef Validator = String? Function(String? value);

Validator required({String message = 'Ce champ est obligatoire.'}) {
  // ...
}

Validator minLength(int min, {String Function(int)? message}) {
  // ...
}

Validator matchesPattern(RegExp pattern, {required String message}) {
  // ...
}

Validator compose(List<Validator> validators) {
  // exécute les validateurs dans l'ordre, retourne le premier message non nul
}
```

Les `TextFormField` de votre formulaire n'appellent, dans leur propriété `validator`, que le résultat de `compose([...])` sur des règles importées de cette couche. Aucune logique de validation (expression régulière, comparaison de longueur, etc.) n'apparaît directement dans un widget.

### 2. Cycle de vie des contrôleurs et des `FocusNode`

Chaque `TextEditingController` et chaque `FocusNode` créé dans le `State` est libéré dans `dispose()`. Démontrez, dans le `README.md`, la fuite obtenue lorsqu'on omet cette libération : décrivez le protocole d'observation utilisé (par exemple DevTools, mémoire, ou un compteur d'instances vivantes que vous instrumentez temporairement), le résultat observé avec et sans `dispose()` correct, et la correction apportée.

### 3. Choix du mode d'auto-validation

`autovalidateMode` doit être choisi champ par champ ou pour l'ensemble du formulaire, en fonction de l'ergonomie attendue. La validation immédiate à chaque frappe (`AutovalidateMode.always` dès la première frappe) est proscrite sur les champs où elle nuit à l'utilisateur — par exemple un champ de courriel qui affiche une erreur avant même que l'utilisateur ait fini de taper. Documentez dans le `README.md`, pour chaque champ, le mode retenu (`disabled`, `onUserInteraction`, `always`, ou une logique conditionnelle que vous implémentez) et sa justification.

### 4. `FormField` personnalisé

Écrivez un `FormField` personnalisé et réutilisable pour un champ non textuel du formulaire — par exemple un sélecteur de plage de dates (début et fin en un seul contrôle) ou un sélecteur de catégories multiples. Ce champ doit s'intégrer correctement au cycle `validate()` et `save()` du `Form` parent : sa valeur doit être récupérée par `FormFieldState.value`, sa validation doit apparaître dans le résultat global de `validate()`, et sa remise à zéro doit répondre à `reset()`. Squelette attendu :

```dart
class DateRangeFormField extends FormField<DateTimeRange> {
  DateRangeFormField({
    super.key,
    required FormFieldSetter<DateTimeRange> onSaved,
    required FormFieldValidator<DateTimeRange> validator,
    DateTimeRange? initialValue,
  }) : super(
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue,
          builder: (FormFieldState<DateTimeRange> state) {
            // ...
          },
        );
}
```

### 5. Formatteur d'entrée pour le tarif

Implémentez un `TextInputFormatter` qui limite la saisie du champ tarif à deux décimales au maximum (empêche la frappe d'un troisième chiffre après le séparateur décimal, sans bloquer la saisie de la partie entière). Squelette attendu :

```dart
class TwoDecimalsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // ...
  }
}
```

### 6. Perte de saisie non soumise

Interceptez la sortie de l'écran (retour, navigation) lorsque le formulaire a été modifié mais non soumis, et demandez confirmation avant d'abandonner la saisie. Le mécanisme choisi (par exemple une interception du retour arrière au niveau de l'écran) doit être décrit dans le `README.md` avec la version de Flutter utilisée, car l'API exacte évolue d'une version à l'autre — vérifiez sur `api.flutter.dev` contre votre `flutter --version` avant de vous engager sur une signature précise.

### 7. Tableau des règles de validation

Le `README.md` doit contenir un tableau au format suivant, une ligne par règle de validation appliquée dans le formulaire de la Partie B :

| Champ | Règle | Message affiché | Cas limites testés |
| --- | --- | --- | --- |
| Courriel de contact | expression régulière de forme générale | « Saisissez une adresse au format nom@domaine.ext » | chaîne vide, absence de `@`, domaine sans point, espace en début de valeur |
| ... | ... | ... | ... |

Le tableau doit couvrir au minimum les dix champs de la Partie B et les quatre contraintes croisées.

**Critères de réussite observables** : aucun fichier de `lib/validation/` n'importe Flutter ; le formulaire compile et valide correctement en n'assemblant que des fonctions de cette couche ; `dispose()` libère explicitement chaque contrôleur et chaque `FocusNode`, nommément listés ; le `FormField` personnalisé répond correctement à `validate()` et `reset()` appelés depuis le `Form` parent ; le tarif ne peut jamais contenir plus de deux décimales, quelle que soit la position du curseur au moment de la frappe.

---

## Partie D — Défi optionnel : parcours multi-étapes

Transformez le formulaire de création d'événement en parcours multi-étapes, avec `Stepper` ou `PageView` — votre choix, à justifier en une phrase dans le `README.md`.

Contraintes :

- chaque étape regroupe un sous-ensemble cohérent de champs (par exemple : informations générales, lieu et horaires, tarification et conditions) ;
- il est impossible d'avancer à l'étape suivante tant que l'étape courante contient un champ invalide ;
- revenir à une étape précédente conserve intégralement la saisie déjà effectuée sur toutes les étapes, y compris celles qui ne sont pas encore visitées à nouveau ;
- un indicateur de progression visible indique l'étape courante et le nombre total d'étapes.

Ajoutez au `README.md` une note d'une demi-page sur les messages d'erreur : expliquez pourquoi un message doit indiquer l'action corrective à entreprendre plutôt que la règle technique violée, et donnez trois exemples de reformulation tirés de votre propre formulaire, sous la forme « message initial » → « message reformulé » → justification de l'amélioration.

---

## Critères d'évaluation

Noté sur 20, bonus plafonné à 2 points.

| Critère | Points |
| --- | --- |
| **Partie A — formulaire d'inscription** | **5** |
| `Form`, `GlobalKey<FormState>`, quatre `TextFormField` avec validateurs élémentaires corrects | 1,5 |
| Clavier adapté par champ (numérique, courriel) | 1 |
| Navigation clavier complète jusqu'à la soumission depuis le dernier champ | 1,5 |
| Soumission bloquée par `validate()`, `reset()` fonctionnel | 1 |
| **Partie B — formulaire de création d'événement** | **6** |
| Dix champs de natures différentes, tous correctement intégrés au `Form` | 1,5 |
| Les quatre contraintes de validation croisée, toutes vérifiées correctement | 2,5 |
| Récapitulatif en lecture seule avant confirmation | 1 |
| Objet de modèle immuable et typé produit à la soumission | 1 |
| **Partie C — architecture et cycle de vie** | **5** |
| Couche de validation pure, sans dépendance Flutter, réellement utilisée par le formulaire | 1,5 |
| Libération de tous les contrôleurs et `FocusNode`, fuite démontrée puis corrigée | 1 |
| Mode d'auto-validation justifié par champ | 0,5 |
| `FormField` personnalisé intégré au cycle `validate`/`save` du parent | 1 |
| Formatteur deux décimales, interception de sortie non soumise, tableau des règles | 1 |
| **Qualité du code** | **2** |
| `flutter analyze` sans avertissement, découpage clair, nommage cohérent | 2 |
| **`USAGE-IA.md`** | **2** |
| Complétude, sincérité, esprit critique sur les réponses obtenues | 2 |
| **Partie D — parcours multi-étapes (bonus)** | **+2** |

Pénalités : usage d'une notion hors périmètre (dépendance de formulaire externe, `provider`, appel réseau, persistance, Firebase, animation) : **−2 points par notion**. Validation écrite avec une bibliothèque tierce plutôt qu'à la main : **−2 points**. Absence de `USAGE-IA.md` : rendu déclaré incomplet.

---

## Livrables

Archive `TP06-NOM-Prenom.zip` ou dépôt git, contenant :

```
event_planner_forms/
├── lib/
│   ├── main.dart
│   ├── models/event_draft.dart
│   ├── validation/
│   │   ├── validators.dart
│   │   └── cross_field_rules.dart
│   ├── formatters/two_decimals_formatter.dart
│   ├── fields/date_range_form_field.dart
│   ├── screens/
│   │   ├── registration_screen.dart
│   │   ├── event_creation_screen.dart
│   │   └── event_summary_screen.dart
│   └── theme/
├── pubspec.yaml
├── README.md
├── USAGE-IA.md
└── captures/                  # captures des messages d'erreur et du récapitulatif
```

Exécutez `flutter clean` avant de constituer l'archive. Les dossiers `build/` et `.dart_tool/` ne doivent pas être remis.

### Livrable obligatoire : `USAGE-IA.md`

L'usage d'un assistant d'IA générative est autorisé et n'a pas à être dissimulé. Il doit en revanche être documenté et instruit. Tout rendu sans ce fichier est incomplet, y compris si aucune IA n'a été utilisée : dans ce cas, le fichier le déclare explicitement.

Le fichier doit permettre à un relecteur de comprendre où s'arrête votre production et où commence celle de la machine. Une entrée par sollicitation significative, dans l'ordre chronologique :

```markdown
# USAGE-IA — TP 6 — <Nom Prénom>

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

- Construire un formulaire : https://docs.flutter.dev/cookbook/forms/validation
- Récupérer la valeur d'un champ de texte : https://docs.flutter.dev/cookbook/forms/retrieve-input
- Gérer le focus et la navigation au clavier : https://docs.flutter.dev/cookbook/forms/focus
- Formater l'entrée avec un `TextInputFormatter` : https://api.flutter.dev/flutter/services/TextInputFormatter-class.html
- `Form` : https://api.flutter.dev/flutter/widgets/Form-class.html
- `FormState` : https://api.flutter.dev/flutter/widgets/FormState-class.html
- `TextFormField` : https://api.flutter.dev/flutter/material/TextFormField-class.html
- `FormField` : https://api.flutter.dev/flutter/widgets/FormField-class.html
- `TextEditingController` : https://api.flutter.dev/flutter/widgets/TextEditingController-class.html

Les signatures évoluent d'une version de Flutter à l'autre : vérifiez systématiquement sur `api.flutter.dev` que l'API que vous employez existe dans la version retournée par `flutter --version`.

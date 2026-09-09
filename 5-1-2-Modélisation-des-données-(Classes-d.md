# 5-1-2 Modélisation des données (Classes de modèles et fromJson)

La manipulation brute de données JSON sous forme de `Map<String, dynamic>` est source d'erreurs. La modélisation consiste à transformer ces données dynamiques en objets typés (classes Dart), garantissant ainsi la sécurité du typage et facilitant la maintenance.

## 1. Concept fondamental
Une classe de modèle représente la structure d'une entité métier. Elle doit être capable de :
*   **Désérialiser** : Convertir un JSON (Map) en objet Dart (`fromJson`).
*   **Sérialiser** : Convertir un objet Dart en JSON (`toJson`).

## 2. Mise en œuvre manuelle
Voici comment structurer une classe pour un utilisateur récupéré depuis une API.

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  // Désérialisation
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  // Sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
```

## 3. Avantages de la modélisation
*   **Auto-complétion :** L'IDE propose les propriétés de l'objet, évitant les fautes de frappe sur les clés JSON.
*   **Sécurité :** Les erreurs de type sont détectées lors de la compilation ou lors de la conversion, et non lors de l'utilisation dans l'interface.
*   **Lisibilité :** Le code est plus explicite (`user.name` vs `user['name']`).

## 4. Bonnes pratiques professionnelles
*   **Immuabilité :** Utilisez le mot-clé `final` pour les propriétés de vos modèles afin de garantir que l'état de l'objet ne change pas après sa création.
*   **Gestion des valeurs nulles :** Si une API peut renvoyer des champs manquants ou `null`, gérez-les explicitement dans le `fromJson` avec des valeurs par défaut ou des types optionnels (`String?`).
*   **Validation :** Vérifiez la présence des champs obligatoires dans le `fromJson` pour éviter les exceptions `TypeError` lors de l'exécution.

## 5. Automatisation avec `json_serializable`
Pour les projets de taille moyenne à grande, écrire manuellement les méthodes `fromJson` et `toJson` devient fastidieux et risqué. L'utilisation du package **json_serializable** est la norme.

1.  Vous annotez votre classe.
2.  Un générateur de code (`build_runner`) crée automatiquement les méthodes de conversion.

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart'; // Fichier généré

@JsonSerializable()
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

## 6. Comparatif : Manuel vs Généré

| Caractéristique | Manuel | Généré (json_serializable) |
| :--- | :--- | :--- |
| **Complexité** | Élevée (risque d'erreur) | Faible (automatisé) |
| **Maintenance** | Manuelle | Automatique |
| **Performance** | Excellente | Excellente |
| **Cas d'usage** | Petits projets / Prototypage | Projets professionnels |

## 7. Erreurs fréquentes et points de vigilance
*   **Types incompatibles :** Tenter de caster un `int` en `String` directement dans le `fromJson` sans conversion préalable.
*   **Oubli de mise à jour :** Modifier la structure de la classe sans relancer la commande `build_runner`, ce qui entraîne des erreurs de désérialisation.
*   **Noms de champs :** Si le JSON utilise des conventions différentes (ex: `snake_case` en API vs `camelCase` en Dart), utilisez `@JsonKey(name: 'user_id')` pour mapper correctement les champs.

## Sources
*   [Dart Documentation - JSON and serialization](https://dart.dev/guides/json)
*   [Pub.dev - json_serializable package](https://pub.dev/packages/json_serializable)
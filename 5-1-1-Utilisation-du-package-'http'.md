# 5-1-1 Utilisation du package 'http'

Le package `http` est la bibliothèque standard de facto pour effectuer des requêtes HTTP dans Flutter. Il fournit des méthodes simples pour interagir avec des API REST.

## 1. Installation
Ajoutez la dépendance dans votre fichier `pubspec.yaml` :

```yaml
dependencies:
  http: ^1.2.0
```

## 2. Fonctionnement détaillé
Le package repose sur des méthodes asynchrones (`Future`) qui retournent un objet `Response`.

### Exemple de requête GET
```dart
import 'package:http/http.dart' as http;

Future<void> fetchUser() async {
  final url = Uri.parse('https://api.example.com/users/1');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    print(response.body);
  } else {
    throw Exception('Échec de la requête : ${response.statusCode}');
  }
}
```

### Exemple de requête POST
```dart
final response = await http.post(
  Uri.parse('https://api.example.com/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'username': 'admin', 'password': '123'}),
);
```

## 3. Comparatif des méthodes HTTP

| Méthode | Usage |
| :--- | :--- |
| `get` | Récupérer des données (lecture seule) |
| `post` | Créer une nouvelle ressource |
| `put` | Mettre à jour une ressource existante (complète) |
| `patch` | Mettre à jour une partie d'une ressource |
| `delete` | Supprimer une ressource |

## 4. Bonnes pratiques professionnelles

*   **Utilisation de `Uri.parse` :** Ne concaténez jamais des chaînes de caractères pour construire une URL. Utilisez `Uri` pour gérer correctement l'encodage des paramètres de requête.
*   **Gestion des erreurs :** Vérifiez systématiquement le `statusCode`. Les codes 2xx indiquent un succès, les 4xx une erreur client, et les 5xx une erreur serveur.
*   **Séparation des couches :** Ne faites jamais d'appels `http` directement dans vos widgets. Créez une classe `ApiService` ou `Repository` dédiée.
*   **Timeout :** Définissez toujours un délai d'attente (timeout) pour éviter que l'application ne reste bloquée indéfiniment en cas de mauvaise connexion.

```dart
final response = await http.get(url).timeout(const Duration(seconds: 10));
```

## 5. Erreurs fréquentes et points de vigilance

*   **Blocage du thread principal :** Bien que `http` soit asynchrone, le traitement du JSON (parsing) peut être coûteux. Pour de très gros volumes de données, utilisez `compute()` pour parser le JSON dans un isolate séparé.
*   **Fuites de ressources :** Pour des requêtes répétées, utilisez `http.Client()` au lieu des fonctions statiques (`http.get`, `http.post`). Cela permet de réutiliser la connexion TCP (Keep-Alive).
*   **Sécurité :** Ne stockez pas de jetons d'authentification (tokens) dans le code source. Utilisez des variables d'environnement ou des systèmes de stockage sécurisés (ex: `flutter_secure_storage`).

## 6. Flux d'une requête réseau

```mermaid
graph LR
    A[Widget] -->|Appel| B[Repository]
    B -->|http.get| C[Serveur API]
    C -->|Response| B
    B -->|Données/Erreur| A
```

## 7. Recommandation actuelle
Le package `http` est idéal pour les besoins simples. Cependant, pour des applications professionnelles nécessitant des fonctionnalités avancées (intercepteurs pour l'authentification, gestion automatique des tokens, upload de fichiers, logs de requêtes), le package **dio** est fortement recommandé. Il offre une API plus riche et une gestion plus robuste des erreurs.

## Sources
*   [Pub.dev - http package](https://pub.dev/packages/http)
*   [Dart Documentation - Asynchronous programming](https://dart.dev/guides/language/language-tour#asynchrony-support)
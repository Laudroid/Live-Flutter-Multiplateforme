# 1-1-2 Architecture technique : Moteur de rendu et langage Dart

La performance de Flutter repose sur deux piliers : son langage de programmation, Dart, et son moteur de rendu graphique.

## 1. Le langage Dart : Moteur de la logique
Dart est un langage optimisé pour les interfaces utilisateur (UI). Il propose deux modes de compilation distincts selon l'environnement :

*   **JIT (Just-In-Time) :** Utilisé lors du développement. Il permet le *Hot Reload*, injectant les modifications de code dans l'application en cours d'exécution sans perdre l'état de l'application.
*   **AOT (Ahead-Of-Time) :** Utilisé pour la production. Le code est compilé en instructions machine natives (ARM ou x64), garantissant une exécution rapide et prévisible.

### Caractéristiques clés
*   **Typage fort :** Détecte les erreurs de type à la compilation.
*   **Null Safety :** Le système de type garantit qu'une variable ne peut pas être `null` sauf si elle est explicitement déclarée comme telle, éliminant les erreurs de type `NullPointerException`.
*   **Asynchronisme :** Basé sur le modèle `Future` et `async/await`, idéal pour les appels API sans bloquer l'interface.

## 2. Le moteur de rendu : De Skia à Impeller
Flutter ne délègue pas le rendu des composants aux widgets natifs de l'OS. Il utilise un moteur graphique pour dessiner chaque pixel.

*   **Skia :** Moteur historique 2D open-source. Il transforme les instructions Flutter en commandes graphiques compréhensibles par le GPU.
*   **Impeller :** Le nouveau moteur de rendu par défaut (sur iOS et progressivement Android). Il résout les problèmes de "jank" (saccades) liés à la compilation des shaders lors de l'exécution en pré-compilant ces derniers.

```mermaid
graph LR
    A[Code Dart] --> B[Framework Flutter]
    B --> C[Moteur Impeller/Skia]
    C --> D[GPU]
```

## 3. Comparatif des modes de compilation

| Mode | Environnement | Avantage principal |
| :--- | :--- | :--- |
| **JIT** | Développement | Hot Reload (productivité) |
| **AOT** | Production | Performance native (vitesse) |

## 4. Bonnes pratiques et points de vigilance

### Utilisation de l'asynchronisme
Pour éviter de figer l'interface lors d'un appel réseau (ex: récupération de données depuis une API REST), utilisez systématiquement `async/await`.

```dart
// Exemple : Appel API asynchrone
Future<void> fetchUserData() async {
  try {
    final response = await http.get(Uri.parse('https://api.entreprise.com/user'));
    if (response.statusCode == 200) {
      // Traitement des données
    }
  } catch (e) {
    // Gestion des erreurs réseau
  }
}
```

### Points de vigilance
*   **Gestion de la mémoire :** Bien que Dart possède un Garbage Collector, évitez de créer des objets inutiles dans la méthode `build()` des widgets, car celle-ci est appelée fréquemment.
*   **Null Safety :** Adoptez le typage strict. Évitez l'usage excessif de `!`, qui force le déballage d'une valeur potentiellement nulle et peut provoquer un crash.
*   **Performance des shaders :** Avec l'adoption d'Impeller, la fluidité est accrue. Assurez-vous de cibler les versions récentes de Flutter pour bénéficier des optimisations liées à ce moteur.

### Erreurs fréquentes
*   **Bloquer le thread principal :** Effectuer des calculs lourds (ex: traitement d'image, parsing JSON massif) directement dans le thread UI. Utilisez `compute()` pour déléguer ces tâches à un *Isolate* (thread séparé).
*   **Ignorer les avertissements du compilateur :** Les warnings de typage sont souvent des indicateurs de bugs potentiels en production.

## Sources
*   [Dart Language Documentation - Null Safety](https://dart.dev/null-safety)
*   [Flutter Documentation - Impeller Rendering Engine](https://docs.flutter.dev/perf/impeller)
*   [Flutter Documentation - Understanding the Flutter Engine](https://docs.flutter.dev/resources/architectural-overview#the-engine)
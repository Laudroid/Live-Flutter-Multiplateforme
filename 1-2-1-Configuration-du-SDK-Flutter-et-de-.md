# 1-2-1 Configuration du SDK Flutter et de l'éditeur

La mise en place d'un environnement de développement robuste est la première étape pour garantir une productivité optimale. Flutter nécessite le SDK (Software Development Kit) et un éditeur configuré avec les extensions appropriées.

## 1. Installation du SDK Flutter

Le SDK Flutter contient les outils nécessaires pour compiler, déboguer et déployer vos applications.

### Étapes d'installation
1.  **Téléchargement :** Récupérez la version stable la plus récente sur le site officiel [flutter.dev](https://flutter.dev).
2.  **Extraction :** Décompressez l'archive dans un répertoire permanent (ex: `C:\src\flutter` sur Windows ou `~/development/flutter` sur macOS/Linux).
3.  **Configuration du PATH :** Ajoutez le sous-dossier `bin` du répertoire Flutter à votre variable d'environnement `PATH`. Cela permet d'exécuter la commande `flutter` depuis n'importe quel terminal.
4.  **Vérification :** Exécutez la commande `flutter doctor` dans votre terminal. Cet outil analyse votre environnement et liste les dépendances manquantes (ex: outils Android, Xcode, simulateurs).

## 2. Choix et configuration de l'éditeur

Deux éditeurs sont principalement utilisés dans le milieu professionnel :

### Visual Studio Code (Recommandé pour la légèreté)
VS Code est l'éditeur le plus utilisé pour Flutter en raison de sa rapidité et de son écosystème d'extensions.
*   **Extension indispensable :** Installez l'extension officielle **"Flutter"** (qui inclut automatiquement l'extension **"Dart"**).
*   **Avantages :** Démarrage rapide, intégration native du terminal, excellente gestion du *Hot Reload*.

### Android Studio (Recommandé pour le débogage complexe)
Android Studio est un IDE complet basé sur IntelliJ.
*   **Configuration :** Installez les plugins "Flutter" et "Dart" via le gestionnaire de plugins.
*   **Avantages :** Outils de profilage mémoire et CPU très avancés, gestion intégrée des émulateurs Android, assistant de configuration pour les SDK natifs.

## 3. Comparatif des outils

| Fonctionnalité | VS Code | Android Studio |
| :--- | :--- | :--- |
| **Consommation RAM** | Faible | Élevée |
| **Vitesse d'ouverture** | Très rapide | Lente |
| **Outils de profilage** | Basiques | Avancés |
| **Configuration** | Simple | Complète |

## 4. Bonnes pratiques professionnelles

*   **Utilisation de `flutter doctor` :** Avant chaque début de projet ou après une mise à jour du SDK, exécutez cette commande pour identifier les problèmes de configuration (ex: licences Android non acceptées).
*   **Gestion des versions :** Utilisez un outil comme `fvm` (Flutter Version Management) pour gérer différentes versions de Flutter par projet. Cela évite les conflits lorsque vous travaillez sur plusieurs applications avec des contraintes de version différentes.
*   **Emulateur vs Appareil physique :** Privilégiez le développement sur un appareil physique (mode développeur activé) pour tester les performances réelles et les interactions tactiles. Utilisez les émulateurs pour tester différentes tailles d'écran et versions d'OS.

## 5. Erreurs fréquentes à éviter

*   **Installer Flutter dans un dossier système :** Évitez les dossiers comme `C:\Program Files` qui nécessitent des droits administrateur pour les mises à jour du SDK.
*   **Ignorer les messages de `flutter doctor` :** Les erreurs concernant les licences Android (`flutter doctor --android-licenses`) sont fréquentes et bloquent la compilation.
*   **Oublier de mettre à jour le SDK :** Flutter évolue rapidement. Utilisez `flutter upgrade` régulièrement pour bénéficier des dernières optimisations du moteur Impeller et des correctifs de sécurité.

## Sources
*   [Documentation officielle : Installation de Flutter](https://docs.flutter.dev/get-started/install)
*   [Documentation officielle : Configuration de l'éditeur](https://docs.flutter.dev/get-started/editor)
*   [FVM (Flutter Version Management)](https://fvm.app/)
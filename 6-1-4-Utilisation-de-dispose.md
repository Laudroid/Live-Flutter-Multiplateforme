La méthode **`dispose()`** est une étape clé du cycle de vie d'un `StatefulWidget`. Son rôle principal est de **nettoyer et libérer les ressources** allouées par l'état du widget (`State`) lorsque celui-ci est définitivement retiré de l'arbre des widgets (*widget tree*).

Sans un appel approprié à `dispose()`, les objets écoutés ou conservés en mémoire continuent d'exister en arrière-plan, provoquant des **fuites de mémoire** (*memory leaks*) et des comportements inattendus.

---

### Ce qu'il faut nettoyer dans `dispose()`

Vous devez surcharger `dispose()` pour fermer ou détruire tout objet qui possède sa propre gestion de cycle de vie ou écoute un flux :

1. **Les contrôleurs de saisie et d'animation :**
* `TextEditingController`
* `AnimationController`
* `ScrollController`
* `PageController`, `TabController`, etc.


2. **Les nœuds de focus :**
* `FocusNode`


3. **Les flux et timers :**
* `StreamSubscription` (abonnements aux streams)
* `Timer` (compte-à-rebours ou intervalles)


4. **Les écouteurs d'événements :**
* `ChangeNotifier` ou `ValueNotifier` personnalisés auxquels vous avez attaché un `.addListener()`.



---

### Règle d'or

L'appel à **`super.dispose()`** doit obligatoirement être la **dernière ligne** de la méthode. Cela permet à la classe parent de finaliser son propre nettoyage une fois vos ressources libérées.

---

### Exemple de code

```dart
class MyFormWidget extends StatefulWidget {
  const MyFormWidget({super.key});

  @override
  State<MyFormWidget> createState() => _MyFormWidgetState();
}

class _MyFormWidgetState extends State<MyFormWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    // 1. Libération des ressources locales
    _controller.dispose();
    _focusNode.dispose();
    _timer?.cancel();

    // 2. Appel au super.dispose() impérativement à la FIN
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
    );
  }
}

```
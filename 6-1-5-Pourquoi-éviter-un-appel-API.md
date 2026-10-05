## Pourquoi éviter un appel API dans `validator`

* **Incompatibilité synchrone :** Le paramètre `validator` attend une fonction synchrone retournant `String?`. Il ne prend pas en charge les `Future<String?>`. Si vous y passez une fonction `async`, Flutter recevra une `Future` (un objet non nul) et considérera le champ comme systématiquement invalide.
* **Exécution fréquente :** Le `validator` est appelé à chaque reconstruction de l'UI ou à chaque frappe clavier (selon `autovalidateMode`). Y placer une requête réseau entraînerait un bombardement d'appels API, du lag visuel, des *race conditions* (réponses réseau reçues dans le désordre) et un surcoût serveur inutile.

---

### Les bonnes pratiques d'implémentation

#### 1. À la soumission du formulaire (La méthode la plus simple et recommandée)

1. Le `validator` synchrone vérifie uniquement la présence et le format de l'email (regex).
2. Lorsque l'utilisateur clique sur "S'inscrire", déclenchez l'appel API global.
3. Si le serveur répond que l'email existe déjà, enregistrez ce message dans l'état de votre widget/controller et rafraîchissez le formulaire pour afficher l'erreur.

#### 2. En temps réel avec un délai d'attente (Debounce)

Si vous souhaitez valider l'unicité pendant la saisie :

* **Anti-rebond (Debounce) :** Attendez que l'utilisateur arrête de taper pendant un court délai (ex. 500 ms) avant de lancer la requête.
* **Indicateur visuel :** Affichez un petit `CircularProgressIndicator` dans le champ pendant la vérification.

---

### Exemple d'implémentation avec Debounce et `setState`

```dart
import 'async' show Timer;
import 'package:flutter/material.dart';

class UniqueEmailFormField extends StatefulWidget {
  const UniqueEmailFormField({super.key});

  @override
  State<UniqueEmailFormField> createState() => _UniqueEmailFormFieldState();
}

class _UniqueEmailFormFieldState extends State<UniqueEmailFormField> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  Timer? _debounceTimer;
  bool _isChecking = false;
  String? _asyncEmailError;

  // Simulation d'un appel API backend
  Future<bool> _checkEmailUniqueness(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Exemple : "test@example.com" est déjà pris
    return email.trim().toLowerCase() != 'test@example.com';
  }

  void _onEmailChanged(String value) {
    // Annule l'erreur précédente dès que l'utilisateur modifie la saisie
    if (_asyncEmailError != null) {
      setState(() => _asyncEmailError = null);
    }

    _debounceTimer?.cancel();
    
    // Si le format n'est pas valide, ne pas surcharger le réseau
    if (value.isEmpty || !_isValidEmailFormat(value)) return;

    // Attend 500ms de pause dans la frappe avant d'appeler l'API
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isChecking = true);
      
      final isUnique = await _checkEmailUniqueness(value);
      
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _asyncEmailError = isUnique ? null : 'Cet e-mail est déjà utilisé.';
      });
      
      // Re-déclenche la validation pour afficher le message sous le champ
      _formKey.currentState?.validate();
    });
  }

  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _onEmailChanged,
            decoration: InputDecoration(
              labelText: 'Adresse e-mail',
              suffixIcon: _isChecking
                  ? const Transform.scale(
                      scale: 0.5,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir un e-mail.';
              }
              if (!_isValidEmailFormat(value)) {
                return 'Format d\'e-mail invalide.';
              }
              // Injection du résultat de la vérification asynchrone
              return _asyncEmailError;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isChecking ? null : () {
              if (_formKey.currentState!.validate()) {
                // Soumettre le formulaire
              }
            },
            child: const Text('S\'inscrire'),
          ),
        ],
      ),
    );
  }
}

```
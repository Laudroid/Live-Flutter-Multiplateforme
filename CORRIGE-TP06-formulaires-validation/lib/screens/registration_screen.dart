import 'package:flutter/material.dart';

import '../validation/validators.dart';

/// Partie A — formulaire d'inscription d'un participant à un événement.
///
/// Volontairement simple : un seul `Form`, quatre champs, navigation clavier
/// complète du premier au dernier champ, soumission conditionnée à
/// `validate()`.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Un contrôleur par champ, déclaré en champ du State : c'est ce qui permet
  // de lire/écrire la valeur du champ indépendamment des rebuilds, et de la
  // réinitialiser explicitement.
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _placesController = TextEditingController();
  final TextEditingController _courrielController = TextEditingController();

  // Un FocusNode par champ pour piloter l'enchaînement au clavier logiciel.
  final FocusNode _nomFocus = FocusNode();
  final FocusNode _villeFocus = FocusNode();
  final FocusNode _placesFocus = FocusNode();
  final FocusNode _courrielFocus = FocusNode();

  @override
  void dispose() {
    // Chaque controller ET chaque FocusNode créé dans le State est libéré
    // ici, nommément. Un oubli ici ne provoque pas d'erreur immédiate et
    // visible : c'est justement ce qui en fait un piège (voir CORRIGE.md).
    _nomController.dispose();
    _villeController.dispose();
    _placesController.dispose();
    _courrielController.dispose();
    _nomFocus.dispose();
    _villeFocus.dispose();
    _placesFocus.dispose();
    _courrielFocus.dispose();
    super.dispose();
  }

  String? _validateNom(String? value) {
    return compose([
      requiredField(message: 'Saisissez votre nom complet.'),
      minLength(1, message: (n) => 'Le nom doit contenir au moins $n caractères.'),
      maxLength(80, message: (n) => 'Le nom ne peut pas dépasser $n caractères.'),
    ])(value);
  }

  String? _validateVille(String? value) {
    return compose([
      requiredField(message: 'Saisissez votre ville de résidence.'),
      minLength(2, message: (n) => 'La ville doit contenir au moins $n caractères.'),
    ])(value);
  }

  String? _validatePlaces(String? value) {
    return compose([
      requiredField(message: 'Saisissez le nombre de places demandées.'),
      integerValue(
        strictlyPositive: true,
        message: 'Saisissez un nombre entier.',
        positiveMessage: 'Le nombre de places doit être strictement positif.',
      ),
    ])(value);
  }

  String? _validateEmail(String? value) {
    return compose([
      requiredField(message: 'Saisissez votre courriel de contact.'),
      matchesPattern(
        emailPattern,
        message: 'Saisissez une adresse au format nom@domaine.ext',
      ),
    ])(value);
  }

  void _submit() {
    final bool estValide = _formKey.currentState!.validate();
    if (!estValide) {
      // Les messages d'erreur sous les champs suffisent : aucune boîte de
      // dialogue supplémentaire n'est requise à ce stade.
      return;
    }
    _formKey.currentState!.save();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inscription enregistrée pour ${_nomController.text}.')),
    );

    _formKey.currentState!.reset();
    // reset() restaure la valeur initiale des TextFormField non contrôlés,
    // mais ici les champs sont pilotés par des TextEditingController : il
    // faut donc aussi vider explicitement les contrôleurs, sans quoi le
    // texte saisi resterait affiché malgré le reset() du Form.
    _nomController.clear();
    _villeController.clear();
    _placesController.clear();
    _courrielController.clear();

    FocusScope.of(context).requestFocus(_nomFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription à un événement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomController,
              focusNode: _nomFocus,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateNom,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_villeFocus);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _villeController,
              focusNode: _villeFocus,
              decoration: const InputDecoration(
                labelText: 'Lieu de résidence (ville)',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateVille,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_placesFocus);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placesController,
              focusNode: _placesFocus,
              decoration: const InputDecoration(
                labelText: 'Nombre de places demandées',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _validatePlaces,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_courrielFocus);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _courrielController,
              focusNode: _courrielFocus,
              decoration: const InputDecoration(
                labelText: 'Courriel de contact',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: _validateEmail,
              // Dernier champ : la validation "done" déclenche directement la
              // tentative de soumission, exactement comme le bouton.
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text("S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../fields/date_range_form_field.dart';
import '../formatters/two_decimals_formatter.dart';
import '../models/event_draft.dart';
import '../validation/cross_field_rules.dart';
import '../validation/validators.dart';
import 'event_summary_screen.dart';

/// Valeur codée en dur représentant le nombre d'inscrits déjà enregistrés
/// pour cet événement (utile pour la modification d'un événement déjà
/// partiellement rempli). Cf. contrainte croisée n°4 de l'énoncé.
const int inscritsExistants = 12;

const List<String> categoriesDisponibles = [
  'Conférence',
  'Atelier',
  'Meetup',
  'Table ronde',
];

/// Partie B (+ Partie C) — formulaire complet de création d'un événement.
class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _capacityFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  String? _category;
  bool _isOnline = false;
  bool _isFree = false;
  bool _acceptedTerms = false;
  DateTimeRange? _dateRange;
  TimeOfDay? _startTime;

  /// Vrai dès que l'utilisateur a modifié quelque chose. Sert à l'interception
  /// de sortie d'écran (PopScope) : on ne demande confirmation que si la
  /// saisie n'a pas encore été soumise.
  bool _isDirty = false;

  void _marquerModifie() {
    _isDirty = true;
  }

  /// Revalide tout le formulaire. Nécessaire lorsqu'un champ non textuel
  /// (interrupteur, case à cocher) change, car son propre changement ne
  /// déclenche pas automatiquement la réévaluation du `validator` d'un
  /// AUTRE champ (par exemple l'adresse), même si ce validator lit l'état de
  /// l'interrupteur. Sans cet appel explicite, l'erreur d'adresse resterait
  /// affichée (ou masquée) avec la valeur périmée de `_isOnline` jusqu'à la
  /// prochaine frappe dans le champ adresse lui-même.
  void _revaliderSiDejaSoumis() {
    if (_isDirty) {
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _capacityFocus.dispose();
    _addressFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    return compose([
      requiredField(message: "Saisissez le titre de l'événement."),
      minLength(2, message: (n) => 'Saisissez au moins $n caractères.'),
      maxLength(120, message: (n) => 'Ne dépassez pas $n caractères.'),
    ])(value);
  }

  String? _validateDescription(String? value) {
    return compose([
      requiredField(message: 'Décrivez votre événement.'),
      minLength(20, message: (n) => 'Ajoutez au moins $n caractères pour être compris des participants.'),
      maxLength(500, message: (n) => 'Raccourcissez votre description à $n caractères maximum.'),
    ])(value);
  }

  String? _validateCapacity(String? value) {
    final String? erreurElementaire = compose([
      requiredField(message: 'Saisissez la capacité maximale.'),
      integerValue(
        strictlyPositive: true,
        positiveMessage: 'La capacité doit être un entier strictement positif.',
      ),
    ])(value);
    if (erreurElementaire != null) return erreurElementaire;
    return validerCapaciteSuffisante(
      capacite: int.tryParse(value!.trim()),
      inscritsExistants: inscritsExistants,
    );
  }

  String? _validateAddress(String? value) {
    return validerAdresseSelonModalite(estEnLigne: _isOnline, adresse: value ?? '');
  }

  String? _validatePrice(String? value) {
    final String? erreurElementaire = decimalValue()(value);
    if (erreurElementaire != null) return erreurElementaire;
    final String? erreurCroisee = validerTarifSelonGratuite(
      estGratuit: _isFree,
      tarifSaisi: value ?? '',
    );
    if (erreurCroisee != null) return erreurCroisee;
    if (!_isFree && (value == null || value.trim().isEmpty)) {
      return "Saisissez un tarif, ou cochez « Événement gratuit ».";
    }
    return null;
  }

  void _voirRecapitulatif() {
    final bool estValide = _formKey.currentState!.validate();
    if (!estValide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrigez les champs signalés avant de continuer.')),
      );
      return;
    }
    _formKey.currentState!.save();

    final EventDraft brouillon = EventDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category!,
      capacity: int.parse(_capacityController.text.trim()),
      isOnline: _isOnline,
      address: _isOnline ? null : _addressController.text.trim(),
      startDate: _dateRange!.start,
      endDate: _dateRange!.end,
      startTime: _startTime!,
      price: _isFree ? 0 : double.parse(_priceController.text.trim()),
      isFree: _isFree,
    );

    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(builder: (_) => EventSummaryScreen(draft: brouillon)),
    )
        .then((bool? confirme) {
      if (confirme == true && mounted) {
        _isDirty = false;
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _confirmerAbandon() async {
    final bool? quitter = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Abandonner la saisie ?'),
        content: const Text(
          'Le formulaire contient des modifications non soumises. '
          'Voulez-vous vraiment quitter sans les enregistrer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuer la saisie'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    if (quitter == true && mounted) {
      _isDirty = false;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      // Point d'API vérifié contre Flutter 3.47.2 : c'est
      // `onPopInvokedWithResult`, pas `onPopInvoked` (retiré), et
      // `WillPopScope` est obsolète depuis Flutter 3.12.
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _confirmerAbandon();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Créer un événement')),
        body: Form(
          key: _formKey,
          onChanged: _marquerModifie,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocus,
                decoration: const InputDecoration(
                  labelText: "Titre de l'événement",
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                // Champ court et sans piège de frappe : signaler l'erreur dès
                // que l'utilisateur a quitté le champ une première fois est
                // acceptable et rend le retour rapide.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateTitle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocus,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                // onUserInteraction : signaler "trop court" pendant que
                // l'utilisateur tape encore serait agressif sur un texte
                // long à rédiger ; on attend une première validation.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateDescription,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: categoriesDisponibles
                    .map((String c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                // always : une liste fermée n'a pas de "saisie en cours", le
                // message peut apparaître dès l'ouverture sans gêner personne
                // une fois qu'un choix a été fait une première fois.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (String? value) {
                  setState(() => _category = value);
                  _marquerModifie();
                },
                onSaved: (String? value) => _category = value,
                validator: (String? value) =>
                    value == null ? 'Choisissez une catégorie.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                focusNode: _capacityFocus,
                decoration: const InputDecoration(
                  labelText: 'Capacité maximale',
                  helperText: 'Doit rester ≥ aux $inscritsExistants inscrits déjà enregistrés.',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateCapacity,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Événement en ligne'),
                value: _isOnline,
                onChanged: (bool value) {
                  setState(() => _isOnline = value);
                  _marquerModifie();
                  // Le changement de cet interrupteur ne fait pas partie du
                  // cycle de validation d'un TextFormField : sans cet appel,
                  // le champ adresse ne réévaluerait sa règle croisée qu'à la
                  // prochaine frappe dans CE champ, pas dans celui-ci.
                  _revaliderSiDejaSoumis();
                },
              ),
              TextFormField(
                controller: _addressController,
                focusNode: _addressFocus,
                decoration: const InputDecoration(
                  labelText: 'Adresse du lieu',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                // disabled : la validité de ce champ dépend entièrement de
                // l'interrupteur "en ligne", pas de son propre contenu tapé
                // au fil de l'eau. On ne le revalide que lors du submit
                // global ou explicitement quand l'interrupteur change (voir
                // _revaliderSiDejaSoumis), jamais frappe par frappe.
                autovalidateMode: AutovalidateMode.disabled,
                validator: _validateAddress,
              ),
              const SizedBox(height: 16),
              DateRangeFormField(
                initialValue: _dateRange,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSaved: (DateTimeRange? value) => _dateRange = value,
                validator: (DateTimeRange? value) => validerDateFinApresDebut(
                  dateDebut: value?.start,
                  dateFin: value?.end,
                ),
              ),
              const SizedBox(height: 16),
              FormField<TimeOfDay>(
                initialValue: _startTime,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSaved: (TimeOfDay? value) => _startTime = value,
                validator: (TimeOfDay? value) =>
                    value == null ? "Choisissez l'heure de début." : null,
                builder: (FormFieldState<TimeOfDay> state) {
                  return InkWell(
                    onTap: () async {
                      final TimeOfDay? choisie = await showTimePicker(
                        context: context,
                        initialTime: state.value ?? TimeOfDay.now(),
                      );
                      if (choisie != null) {
                        state.didChange(choisie);
                        _marquerModifie();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Heure de début',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.access_time),
                        errorText: state.errorText,
                      ),
                      child: Text(state.value?.format(context) ?? 'Choisir une heure'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                focusNode: _priceFocus,
                decoration: const InputDecoration(
                  labelText: 'Tarif (€)',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [TwoDecimalsFormatter()],
                // onUserInteraction : un montant se compose progressivement
                // (partie entière puis décimales) ; valider dès la première
                // frappe afficherait une erreur sur un "1" en cours de saisie
                // de "12.50".
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePrice,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Événement gratuit'),
                value: _isFree,
                onChanged: (bool? value) {
                  setState(() => _isFree = value ?? false);
                  _marquerModifie();
                  // Même raisonnement que pour l'interrupteur "en ligne" :
                  // cocher "gratuit" doit immédiatement révéler l'incohérence
                  // si un tarif non nul est déjà saisi, sans attendre une
                  // frappe dans le champ tarif.
                  _revaliderSiDejaSoumis();
                },
              ),
              FormField<bool>(
                initialValue: _acceptedTerms,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSaved: (bool? value) => _acceptedTerms = value ?? false,
                validator: (bool? value) => value == true
                    ? null
                    : "Cochez la case pour accepter les conditions d'organisation.",
                builder: (FormFieldState<bool> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: const Text("J'accepte les conditions d'organisation"),
                        value: state.value ?? false,
                        onChanged: (bool? value) {
                          state.didChange(value);
                          _marquerModifie();
                        },
                      ),
                      if (state.errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _voirRecapitulatif,
                child: const Text('Voir le récapitulatif'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

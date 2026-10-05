import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// `FormField` personnalisé et réutilisable pour un champ non textuel : un
/// sélecteur de plage de dates (date de début + date de fin) présenté comme
/// un contrôle unique.
///
/// Choix de conception : on hérite directement de `FormField<DateTimeRange>`
/// plutôt que d'écrire un `StatefulWidget` séparé qui communiquerait sa valeur
/// au `Form` via un `GlobalKey` ou un callback ad hoc. En héritant de
/// `FormField`, ce widget bénéficie gratuitement de l'intégration avec
/// `FormState.validate()` (son `validator` est appelé et son message
/// d'erreur apparaît dans le résultat global), `FormState.save()` (son
/// `onSaved` est invoqué avec `state.value`) et `FormState.reset()` (la
/// valeur revient à `initialValue` et l'affichage se met à jour). C'est
/// exactement ce que demande l'énoncé : « sa valeur doit être récupérée par
/// FormFieldState.value ».
class DateRangeFormField extends FormField<DateTimeRange> {
  DateRangeFormField({
    super.key,
    required FormFieldSetter<DateTimeRange> onSaved,
    required FormFieldValidator<DateTimeRange> validator,
    super.initialValue,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          onSaved: onSaved,
          validator: validator,
          autovalidateMode: autovalidateMode,
          builder: (FormFieldState<DateTimeRange> state) {
            final DateFormat formateur = DateFormat('dd/MM/yyyy');
            final DateTimeRange? valeur = state.value;
            final String texteAffiche = valeur == null
                ? 'Choisir les dates de début et de fin'
                : '${formateur.format(valeur.start)}  →  '
                    '${formateur.format(valeur.end)}';

            Future<void> ouvrirSelecteur() async {
              final DateTime maintenant = DateTime.now();
              final DateTimeRange? resultat = await showDateRangePicker(
                context: state.context,
                firstDate: DateTime(maintenant.year - 1),
                lastDate: DateTime(maintenant.year + 3),
                initialDateRange: valeur,
                helpText: 'Sélectionnez les dates de début et de fin',
              );
              if (resultat != null) {
                // didChange() met à jour state.value ET déclenche la
                // revalidation si autovalidateMode l'exige : c'est le point
                // d'entrée normal pour faire évoluer la valeur d'un
                // FormField personnalisé.
                state.didChange(resultat);
              }
            }

            return InkWell(
              onTap: ouvrirSelecteur,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Dates de début et de fin',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.date_range),
                  errorText: state.errorText,
                ),
                child: Text(texteAffiche),
              ),
            );
          },
        );
}

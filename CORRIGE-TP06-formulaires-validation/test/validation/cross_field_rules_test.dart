import 'package:flutter_test/flutter_test.dart';

import 'package:corrige_tp06_formulaires/validation/cross_field_rules.dart';

void main() {
  group('validerDateFinApresDebut', () {
    test('signale l\'absence de date de début sans lever d\'exception', () {
      expect(
        () => validerDateFinApresDebut(dateDebut: null, dateFin: null),
        returnsNormally,
      );
      expect(
        validerDateFinApresDebut(dateDebut: null, dateFin: null),
        isNotNull,
      );
    });

    test('signale l\'absence de date de fin quand la date de début existe', () {
      final DateTime debut = DateTime(2026, 3, 1);
      expect(validerDateFinApresDebut(dateDebut: debut, dateFin: null), isNotNull);
    });

    test('rejette une date de fin antérieure à la date de début', () {
      final DateTime debut = DateTime(2026, 3, 10);
      final DateTime fin = DateTime(2026, 3, 5);
      expect(validerDateFinApresDebut(dateDebut: debut, dateFin: fin), isNotNull);
    });

    test('rejette une date de fin égale à la date de début (strictement postérieure exigé)', () {
      final DateTime meme = DateTime(2026, 3, 10);
      expect(validerDateFinApresDebut(dateDebut: meme, dateFin: meme), isNotNull);
    });

    test('accepte une date de fin postérieure à la date de début', () {
      final DateTime debut = DateTime(2026, 3, 10);
      final DateTime fin = DateTime(2026, 3, 11);
      expect(validerDateFinApresDebut(dateDebut: debut, dateFin: fin), isNull);
    });
  });

  group('validerAdresseSelonModalite', () {
    test('rejette une adresse vide si événement en présentiel', () {
      expect(
        validerAdresseSelonModalite(estEnLigne: false, adresse: ''),
        isNotNull,
      );
    });

    test('accepte une adresse renseignée si événement en présentiel', () {
      expect(
        validerAdresseSelonModalite(estEnLigne: false, adresse: '12 rue des Lilas'),
        isNull,
      );
    });

    test('rejette une adresse renseignée si événement en ligne', () {
      expect(
        validerAdresseSelonModalite(estEnLigne: true, adresse: '12 rue des Lilas'),
        isNotNull,
      );
    });

    test('accepte une adresse vide si événement en ligne', () {
      expect(validerAdresseSelonModalite(estEnLigne: true, adresse: ''), isNull);
    });

    test('accepte une adresse composée uniquement d\'espaces comme vide, événement en ligne', () {
      expect(validerAdresseSelonModalite(estEnLigne: true, adresse: '   '), isNull);
    });
  });

  group('validerTarifSelonGratuite', () {
    test('accepte un tarif vide si événement gratuit', () {
      expect(validerTarifSelonGratuite(estGratuit: true, tarifSaisi: ''), isNull);
    });

    test('accepte un tarif à zéro si événement gratuit', () {
      expect(validerTarifSelonGratuite(estGratuit: true, tarifSaisi: '0'), isNull);
    });

    test('rejette un tarif non nul si événement gratuit', () {
      expect(validerTarifSelonGratuite(estGratuit: true, tarifSaisi: '12.00'), isNotNull);
    });

    test('n\'impose rien si événement non gratuit', () {
      expect(validerTarifSelonGratuite(estGratuit: false, tarifSaisi: '12.00'), isNull);
      expect(validerTarifSelonGratuite(estGratuit: false, tarifSaisi: ''), isNull);
    });
  });

  group('validerCapaciteSuffisante', () {
    const int inscrits = 12;

    test('rejette une capacité absente', () {
      expect(
        validerCapaciteSuffisante(capacite: null, inscritsExistants: inscrits),
        isNotNull,
      );
    });

    test('rejette une capacité strictement inférieure aux inscrits existants', () {
      expect(
        validerCapaciteSuffisante(capacite: 10, inscritsExistants: inscrits),
        isNotNull,
      );
    });

    test('accepte une capacité égale au nombre d\'inscrits existants', () {
      expect(
        validerCapaciteSuffisante(capacite: 12, inscritsExistants: inscrits),
        isNull,
      );
    });

    test('accepte une capacité supérieure au nombre d\'inscrits existants', () {
      expect(
        validerCapaciteSuffisante(capacite: 50, inscritsExistants: inscrits),
        isNull,
      );
    });
  });
}

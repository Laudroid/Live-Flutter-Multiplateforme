import 'package:flutter_test/flutter_test.dart';

import 'package:corrige_tp06_formulaires/validation/validators.dart';

void main() {
  group('requiredField', () {
    final Validator v = requiredField(message: 'obligatoire');
    test('rejette null', () => expect(v(null), 'obligatoire'));
    test('rejette chaîne vide', () => expect(v(''), 'obligatoire'));
    test('rejette espaces seuls', () => expect(v('   '), 'obligatoire'));
    test('accepte une valeur non vide', () => expect(v('Paris'), isNull));
  });

  group('minLength', () {
    final Validator v = minLength(2, message: (n) => 'min $n');
    test('rejette une valeur trop courte', () => expect(v('a'), 'min 2'));
    test('accepte la longueur minimale exacte', () => expect(v('ab'), isNull));
    test('ignore un champ vide (délégué à requiredField)', () => expect(v(''), isNull));
  });

  group('maxLength', () {
    final Validator v = maxLength(3, message: (n) => 'max $n');
    test('rejette une valeur trop longue', () => expect(v('abcd'), 'max 3'));
    test('accepte la longueur maximale exacte', () => expect(v('abc'), isNull));
  });

  group('matchesPattern (email)', () {
    final Validator v = matchesPattern(emailPattern, message: 'format invalide');

    test('accepte une adresse simple', () => expect(v('nom@domaine.com'), isNull));
    test('accepte une adresse avec sous-domaine', () => expect(v('nom@mail.exemple.fr'), isNull));
    test('rejette une chaîne sans arobase', () => expect(v('nomdomaine.com'), isNotNull));
    test('rejette un domaine sans point', () => expect(v('nom@domaine'), isNotNull));
    test('rejette une espace en début de valeur', () => expect(v(' nom@domaine.com'), isNotNull));
    test('rejette une arobase en double', () => expect(v('nom@@domaine.com'), isNotNull));
    test('ignore un champ vide (délégué à requiredField)', () => expect(v(''), isNull));
  });

  group('integerValue', () {
    final Validator v = integerValue(strictlyPositive: true, positiveMessage: 'positif');
    test('rejette une valeur non numérique', () => expect(v('abc'), isNotNull));
    test('rejette zéro (pas strictement positif)', () => expect(v('0'), 'positif'));
    test('rejette un négatif', () => expect(v('-3'), 'positif'));
    test('accepte un entier positif', () => expect(v('12'), isNull));
    test('rejette un décimal', () => expect(v('1.5'), isNotNull));
  });

  group('decimalValue', () {
    final Validator v = decimalValue();
    test('accepte un montant décimal', () => expect(v('12.50'), isNull));
    test('accepte zéro', () => expect(v('0'), isNull));
    test('rejette un négatif', () => expect(v('-1'), isNotNull));
    test('rejette une valeur non numérique', () => expect(v('douze'), isNotNull));
  });

  group('compose', () {
    test('retourne le premier message non nul dans l\'ordre', () {
      final Validator v = compose([
        requiredField(message: 'obligatoire'),
        minLength(5, message: (n) => 'min $n'),
      ]);
      expect(v(''), 'obligatoire');
      expect(v('ab'), 'min 5');
      expect(v('abcdef'), isNull);
    });

    test('retourne null si toutes les règles passent', () {
      final Validator v = compose([requiredField(), minLength(1)]);
      expect(v('x'), isNull);
    });
  });
}

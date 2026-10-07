import 'package:flutter_test/flutter_test.dart';

import 'package:corrige_tp07_stockage_local/models/event_draft.dart';

void main() {
  group('EventDraft — sérialisation', () {
    test('aller-retour toJson/fromJson préserve les champs', () {
      final original = EventDraft(
        id: 'evt-1',
        title: 'Conférence Flutter',
        location: 'Lyon',
        date: DateTime.utc(2026, 10, 1, 9, 30),
        category: 'tech',
        reminderEnabled: true,
      );

      final restored = EventDraft.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.location, original.location);
      expect(restored.date, original.date);
      expect(restored.category, original.category);
      expect(restored.reminderEnabled, original.reminderEnabled);
    });

    test('toJson porte le schemaVersion courant', () {
      final draft = EventDraft(id: 'evt-2');
      expect(draft.toJson()['schemaVersion'], currentDraftSchemaVersion);
    });
  });

  group('EventDraft — migration de schéma version 1 vers 2', () {
    test('un JSON version 1 avec "city" est relu comme "location", '
        'et reminderEnabled prend sa valeur par défaut', () {
      // JSON tel qu'écrit par une ancienne version de l'application :
      // schéma 1, champ "city", pas de "reminderEnabled".
      final legacyJson = <String, dynamic>{
        'schemaVersion': 1,
        'id': 'evt-legacy',
        'title': 'Salon du livre',
        'city': 'Bordeaux',
        'date': null,
        'category': 'culture',
        'updatedAt': '2025-01-15T10:00:00.000Z',
      };

      final migrated = EventDraft.fromJson(legacyJson);

      expect(migrated.id, 'evt-legacy');
      expect(migrated.location, 'Bordeaux',
          reason: 'le champ renommé city -> location doit être préservé');
      expect(migrated.reminderEnabled, false,
          reason: 'valeur par défaut appliquée au champ ajouté');
    });

    test('un JSON sans schemaVersion du tout est traité comme version 1', () {
      final veryOldJson = <String, dynamic>{
        'id': 'evt-very-old',
        'title': '',
        'city': 'Nice',
        'category': '',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final migrated = EventDraft.fromJson(veryOldJson);

      expect(migrated.location, 'Nice');
      expect(migrated.reminderEnabled, false);
    });

    test('un JSON version 2 utilise directement "location" et "reminderEnabled"', () {
      final currentJson = <String, dynamic>{
        'schemaVersion': 2,
        'id': 'evt-current',
        'title': 'Marathon',
        'location': 'Paris',
        'date': null,
        'category': 'sport',
        'reminderEnabled': true,
        'updatedAt': '2026-05-01T08:00:00.000Z',
      };

      final draft = EventDraft.fromJson(currentJson);

      expect(draft.location, 'Paris');
      expect(draft.reminderEnabled, true);
    });
  });
}

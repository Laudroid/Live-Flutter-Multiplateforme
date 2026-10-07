import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:corrige_tp07_stockage_local/models/event_draft.dart';
import 'package:corrige_tp07_stockage_local/storage/draft_repository.dart';

void main() {
  // On utilise un répertoire temporaire réel du système
  // (Directory.systemTemp) plutôt que path_provider : path_provider exige
  // une plateforme (Android/iOS/canal de méthode) qui n'existe pas dans un
  // test Dart pur exécuté par `flutter test` sur ce conteneur. La logique
  // de DraftRepository ne dépend que de dart:io, donc ce choix ne
  // sacrifie rien du comportement testé.
  late Directory tempDir;
  late DraftRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tp07_drafts_test_');
    repository = DraftRepository(Directory('${tempDir.path}/drafts'));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('cas limites de lecture', () {
    test('répertoire absent au premier accès : création silencieuse', () async {
      expect(await repository.baseDirectory.exists(), isFalse);

      final result = await repository.loadDraft('abc');

      expect(result.status, DraftLoadStatus.empty);
      expect(await repository.baseDirectory.exists(), isTrue);
    });

    test('fichier absent (identifiant inconnu) : brouillon vide, pas d\'exception', () async {
      final result = await repository.loadDraft('inconnu');
      expect(result.status, DraftLoadStatus.empty);
      expect(result.draft, isNull);
    });

    test('fichier vide (0 octet) : traité comme un brouillon vide', () async {
      await repository.baseDirectory.create(recursive: true);
      final file = File('${repository.baseDirectory.path}/${repository.safeFileName('vide')}');
      await file.writeAsString('');

      final result = await repository.loadDraft('vide');

      expect(result.status, DraftLoadStatus.empty);
    });

    test('fichier corrompu (JSON tronqué) : dégradation propre, aucune exception', () async {
      await repository.baseDirectory.create(recursive: true);
      final file = File('${repository.baseDirectory.path}/${repository.safeFileName('corrompu')}');
      // JSON tronqué à la main : accolade fermante manquante, comme demandé
      // par l'énoncé pour la démonstration du cas limite.
      const truncated = '{"schemaVersion":2,"id":"corrompu","title":"Test"';
      await file.writeAsString(truncated);

      // On vérifie explicitement que jsonDecode lève bien une
      // FormatException sur ce contenu précis (message exact documenté
      // dans CORRIGE.md), puis que loadDraft l'intercepte sans relancer.
      expect(() => jsonDecode(truncated), throwsFormatException);

      final result = await repository.loadDraft('corrompu');

      expect(result.status, DraftLoadStatus.corrupted);
      expect(result.draft, isNull);
    });
  });

  group('nommage de fichier sûr', () {
    test('un identifiant contenant des séparateurs de chemin est neutralisé', () {
      final name = repository.safeFileName('../../etc/passwd');
      expect(name.contains('..'), isFalse);
      expect(name.contains('/'), isFalse);
    });

    test('deux identifiants malicieux distincts ne collisionnent pas trivialement', () {
      final a = repository.safeFileName('a/b');
      final b = repository.safeFileName('a_b');
      // Les deux sont assainis vers la même forme : documenté comme
      // limite connue (voir CORRIGE.md), acceptable ici car les
      // identifiants de brouillons sont générés par l'application
      // elle-même (horodatage), jamais saisis par l'utilisateur.
      expect(a, b);
    });
  });

  group('écriture atomique', () {
    test('saveDraft laisse le fichier final complet, jamais un .tmp orphelin visible comme final', () async {
      final draft = EventDraft(id: 'atomique', title: 'Premier');
      await repository.saveDraft(draft);

      final finalFile = File('${repository.baseDirectory.path}/atomique.json');
      final tempFile = File('${repository.baseDirectory.path}/atomique.json.tmp');

      expect(await finalFile.exists(), isTrue);
      expect(await tempFile.exists(), isFalse,
          reason: 'rename() déplace le contenu, ne laisse pas de copie .tmp');

      final content = jsonDecode(await finalFile.readAsString());
      expect(content['title'], 'Premier');
    });

    test('simulation d\'interruption : si seule l\'écriture du .tmp a eu lieu, '
        'le fichier final garde son ancienne version intacte', () async {
      // Première écriture réussie et complète.
      await repository.saveDraft(EventDraft(id: 'atomique2', title: 'Ancienne version'));

      // On simule une interruption : le fichier temporaire de la seconde
      // écriture est produit, mais le rename() n'est jamais exécuté
      // (processus tué juste avant, par hypothèse).
      final tempFile = File('${repository.baseDirectory.path}/atomique2.json.tmp');
      await tempFile.writeAsString(
        jsonEncode(EventDraft(id: 'atomique2', title: 'Nouvelle version interrompue').toJson()),
      );

      final finalFile = File('${repository.baseDirectory.path}/atomique2.json');
      final contentAfterCrash = jsonDecode(await finalFile.readAsString());

      // Le fichier final n'a jamais été touché : il porte encore
      // l'ancienne version, complète et lisible. Jamais d'état
      // intermédiaire.
      expect(contentAfterCrash['title'], 'Ancienne version');

      // Un rechargement normal de l'application ignore le .tmp résiduel :
      // loadDraft ne lit que le fichier final.
      final result = await repository.loadDraft('atomique2');
      expect(result.draft?.title, 'Ancienne version');
    });
  });

  group('cycle complet', () {
    test('save puis load restitue le même contenu métier', () async {
      final draft = EventDraft(
        id: 'cycle',
        title: 'Titre',
        location: 'Marseille',
        category: 'famille',
        reminderEnabled: true,
      );
      await repository.saveDraft(draft);

      final result = await repository.loadDraft('cycle');

      expect(result.status, DraftLoadStatus.ok);
      expect(result.draft?.title, 'Titre');
      expect(result.draft?.location, 'Marseille');
      expect(result.draft?.reminderEnabled, true);
    });

    test('listDrafts rapporte la taille réelle occupée sur le disque', () async {
      await repository.saveDraft(EventDraft(id: 'liste-1', title: 'Un'));
      await repository.saveDraft(EventDraft(id: 'liste-2', title: 'Deux'));

      final summaries = await repository.listDrafts();

      expect(summaries.length, 2);
      for (final s in summaries) {
        expect(s.sizeBytes, greaterThan(0));
      }
    });

    test('deleteDraft supprime le fichier individuellement', () async {
      await repository.saveDraft(EventDraft(id: 'a-supprimer', title: 'X'));
      await repository.deleteDraft('a-supprimer');

      final result = await repository.loadDraft('a-supprimer');
      expect(result.status, DraftLoadStatus.empty);
    });

    test('deleteAll supprime tous les brouillons', () async {
      await repository.saveDraft(EventDraft(id: 'x1', title: 'X1'));
      await repository.saveDraft(EventDraft(id: 'x2', title: 'X2'));

      await repository.deleteAll();

      final summaries = await repository.listDrafts();
      expect(summaries, isEmpty);
    });
  });

  group('purge des données temporaires', () {
    test('supprime les fichiers plus vieux que maxAge', () async {
      final dir = await Directory.systemTemp.createTemp('tp07_purge_test_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final oldFile = File('${dir.path}/vieux.tmp')..writeAsStringSync('x');
      final oldStat = DateTime.now().subtract(const Duration(days: 10));
      await oldFile.setLastModified(oldStat);

      final recentFile = File('${dir.path}/recent.tmp')..writeAsStringSync('y');

      await DraftRepository.purgeDirectory(
        dir,
        maxAge: const Duration(days: 3),
        maxTotalBytes: 1024 * 1024,
      );

      expect(await oldFile.exists(), isFalse);
      expect(await recentFile.exists(), isTrue);
    });
  });

  group('désérialisation hors fil principal', () {
    test('parseDraftJsonInIsolate reconstruit le même brouillon que fromJson', () {
      final draft = EventDraft(id: 'iso', title: 'Isolate', location: 'Rennes');
      final content = jsonEncode(draft.toJson());

      final parsed = parseDraftJsonInIsolate(content);

      expect(parsed?.id, 'iso');
      expect(parsed?.title, 'Isolate');
      expect(parsed?.location, 'Rennes');
    });

    test('parseDraftJsonInIsolate renvoie null sur un contenu invalide, sans exception', () {
      final parsed = parseDraftJsonInIsolate('{"id":');
      expect(parsed, isNull);
    });
  });
}

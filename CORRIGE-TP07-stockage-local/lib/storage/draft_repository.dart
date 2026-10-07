import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;

import '../models/event_draft.dart';

/// Résultat de la lecture d'un brouillon : distingue explicitement les
/// trois cas limites de l'énoncé pour que l'écran d'édition puisse afficher
/// le message adapté sans jamais laisser fuir une exception.
enum DraftLoadStatus {
  /// Le fichier existe, contient un JSON valide : [DraftLoadResult.draft]
  /// est renseigné.
  ok,

  /// Le fichier est absent, ou présent mais vide (0 octet) : traité comme
  /// un brouillon neuf, pas comme une erreur.
  empty,

  /// Le fichier existe, contient des octets, mais le JSON est invalide
  /// (tronqué, corrompu). Ne doit jamais lever d'exception non interceptée.
  corrupted,
}

class DraftLoadResult {
  const DraftLoadResult(this.status, this.draft);

  final DraftLoadStatus status;
  final EventDraft? draft;
}

/// Résumé d'un brouillon pour l'écran de liste : évite de désérialiser tout
/// le contenu quand seuls le titre, la date et la taille sont affichés.
class DraftSummary {
  const DraftSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.sizeBytes,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int sizeBytes;

  String get displayTitle => title.isEmpty ? '(sans titre)' : title;
}

/// Fonction top-level (et non une méthode d'instance) car c'est la
/// signature exigée par `compute()` pour s'exécuter dans une isolate
/// séparée : elle ne doit capturer aucun état de l'instance appelante.
/// Utilisée pour désérialiser le plus gros fichier de brouillons hors du
/// fil d'interface (voir Partie C, point 5, et la justification dans
/// CORRIGE.md).
EventDraft? parseDraftJsonInIsolate(String rawContent) {
  if (rawContent.trim().isEmpty) return null;
  try {
    final json = jsonDecode(rawContent) as Map<String, dynamic>;
    return EventDraft.fromJson(json);
  } on FormatException {
    return null;
  }
}

/// Couche de persistance des brouillons sur disque.
///
/// Le répertoire de base est injecté au constructeur plutôt qu'obtenu en
/// interne via `path_provider` : cela rend la classe testable avec
/// `Directory.systemTemp` dans des tests Dart purs (sans plateforme), tout
/// en utilisant `getApplicationDocumentsDirectory()` en production (câblé
/// dans `main.dart`).
class DraftRepository {
  DraftRepository(this.baseDirectory);

  final Directory baseDirectory;

  /// Crée le répertoire s'il est absent. Appelé avant toute opération de
  /// lecture ou écriture : un répertoire de documents absent au premier
  /// accès ne doit jamais produire d'exception visible.
  Future<void> _ensureDirectory() async {
    if (!await baseDirectory.exists()) {
      await baseDirectory.create(recursive: true);
    }
  }

  /// Construit un nom de fichier déterministe et sûr à partir de
  /// l'identifiant du brouillon : seuls les caractères alphanumériques,
  /// `-` et `_` sont conservés, tout le reste (séparateurs de chemin,
  /// `..`, espaces) est remplacé par `_`. Cela empêche un identifiant
  /// malveillant ou accidentel de sortir du répertoire de brouillons ou de
  /// produire un chemin invalide.
  String safeFileName(String id) {
    final sanitized = id.replaceAll(RegExp(r'[^A-Za-z0-9\-_]'), '_');
    final safe = sanitized.isEmpty ? '_' : sanitized;
    return '$safe.json';
  }

  File _finalFile(String id) => File('${baseDirectory.path}/${safeFileName(id)}');

  File _tempFile(String id) => File('${baseDirectory.path}/${safeFileName(id)}.tmp');

  /// Charge un brouillon. Ne lève jamais d'exception : toute anomalie est
  /// traduite en [DraftLoadStatus].
  Future<DraftLoadResult> loadDraft(String id) async {
    await _ensureDirectory();
    final file = _finalFile(id);
    if (!await file.exists()) {
      return const DraftLoadResult(DraftLoadStatus.empty, null);
    }
    final String content;
    try {
      content = await file.readAsString();
    } on FileSystemException {
      return const DraftLoadResult(DraftLoadStatus.corrupted, null);
    }
    if (content.trim().isEmpty) {
      return const DraftLoadResult(DraftLoadStatus.empty, null);
    }
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DraftLoadResult(DraftLoadStatus.ok, EventDraft.fromJson(json));
    } on FormatException {
      // JSON tronqué ou corrompu : dégradation propre, pas de plantage.
      return const DraftLoadResult(DraftLoadStatus.corrupted, null);
    } on TypeError {
      // Champ de type inattendu (JSON valide mais forme incorrecte).
      return const DraftLoadResult(DraftLoadStatus.corrupted, null);
    }
  }

  /// Écrit le brouillon de façon atomique : le contenu est d'abord écrit
  /// dans un fichier temporaire distinct (`<id>.json.tmp`), puis ce fichier
  /// est renommé vers le nom final. `File.rename` remplace le fichier de
  /// destination en une seule opération système ; si le processus est tué
  /// entre l'écriture du fichier temporaire et le renommage, le fichier
  /// final reste soit absent, soit dans son ancien état intact — jamais à
  /// moitié écrit.
  Future<void> saveDraft(EventDraft draft) async {
    await _ensureDirectory();
    final tempFile = _tempFile(draft.id);
    final content = jsonEncode(draft.toJson());
    await tempFile.writeAsString(content, flush: true);
    await tempFile.rename(_finalFile(draft.id).path);
  }

  Future<void> deleteDraft(String id) async {
    final file = _finalFile(id);
    if (await file.exists()) {
      await file.delete();
    }
    final temp = _tempFile(id);
    if (await temp.exists()) {
      await temp.delete();
    }
  }

  Future<void> deleteAll() async {
    if (!await baseDirectory.exists()) return;
    final entries = await baseDirectory.list().toList();
    for (final entry in entries) {
      if (entry is File && entry.path.endsWith('.json')) {
        await entry.delete();
      }
    }
  }

  /// Liste tous les brouillons présents sur le disque. Un fichier
  /// individuellement corrompu est ignoré dans la liste plutôt que de
  /// faire échouer l'ensemble de l'écran.
  Future<List<DraftSummary>> listDrafts() async {
    await _ensureDirectory();
    final entries = await baseDirectory.list().toList();
    final summaries = <DraftSummary>[];
    for (final entry in entries) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      final fileName = entry.uri.pathSegments.last;
      final id = fileName.substring(0, fileName.length - '.json'.length);
      final stat = await entry.stat();
      String content;
      try {
        content = await entry.readAsString();
      } on FileSystemException {
        continue;
      }
      EventDraft? draft;
      if (content.trim().isNotEmpty) {
        // Le plus gros fichier de la liste est celui qui justifie un
        // passage hors du fil principal ; ici la désérialisation est
        // faite via la fonction top-level pour rester compatible avec
        // `compute()` (voir `loadLargestDraftOffMainThread`).
        draft = parseDraftJsonInIsolate(content);
      }
      summaries.add(DraftSummary(
        id: id,
        title: draft?.title ?? '',
        updatedAt: draft?.updatedAt ?? stat.modified,
        sizeBytes: stat.size,
      ));
    }
    summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return summaries;
  }

  /// Désérialise un contenu de brouillon hors du fil principal via
  /// `compute()`. Réservé au plus gros fichier rencontré (voir Partie C
  /// point 5) : le coût de démarrage d'une isolate n'est justifié que pour
  /// un contenu réellement volumineux, pas pour chaque petit brouillon.
  Future<EventDraft?> parseLargeDraftOffMainThread(String rawContent) {
    return compute(parseDraftJsonInIsolate, rawContent);
  }

  /// Politique de purge : supprime dans [directory] les fichiers plus
  /// vieux que [maxAge], puis, si la taille cumulée restante dépasse
  /// encore [maxTotalBytes], supprime les fichiers restants du plus ancien
  /// au plus récent jusqu'à repasser sous la limite. Les deux critères
  /// sont donc combinés, le plus contraignant l'emportant de fait puisque
  /// l'un est appliqué après l'autre.
  static Future<void> purgeDirectory(
    Directory directory, {
    required Duration maxAge,
    required int maxTotalBytes,
  }) async {
    if (!await directory.exists()) return;
    final now = DateTime.now();
    final files = await directory
        .list()
        .where((entry) => entry is File)
        .cast<File>()
        .toList();

    final remaining = <File>[];
    for (final file in files) {
      final stat = await file.stat();
      if (now.difference(stat.modified) > maxAge) {
        await file.delete();
      } else {
        remaining.add(file);
      }
    }

    final stats = <File, FileStat>{};
    var total = 0;
    for (final file in remaining) {
      final stat = await file.stat();
      stats[file] = stat;
      total += stat.size;
    }
    remaining.sort(
      (a, b) => stats[a]!.modified.compareTo(stats[b]!.modified),
    );
    for (final file in remaining) {
      if (total <= maxTotalBytes) break;
      total -= stats[file]!.size;
      await file.delete();
    }
  }
}

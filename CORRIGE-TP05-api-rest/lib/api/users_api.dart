import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/participant.dart';
import '../models/participant_detail.dart';
import 'exceptions.dart';

/// Réponse paginée de `/users` et `/users/search` : la liste ainsi que les
/// informations nécessaires pour savoir s'il reste des pages à charger.
class UsersPage {
  const UsersPage({
    required this.participants,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Participant> participants;
  final int total;
  final int skip;
  final int limit;

  /// Vrai s'il reste des utilisateurs au-delà de cette page.
  bool get hasMore => skip + participants.length < total;
}

/// Couche client HTTP isolée : c'est le seul endroit du projet qui appelle
/// `http.Client`. Le reste de l'application (écrans, widgets) ne connaît
/// que [UsersApi], [UsersPage], [Participant] et [ApiException].
///
/// Choix de conception :
/// - une seule instance de [http.Client] est réutilisée (voir le
///   constructeur) plutôt que d'appeler la fonction statique `http.get` à
///   chaque requête, pour permettre la réutilisation de la connexion TCP
/// - chaque requête est bornée par [_timeout], explicite, pour ne jamais
///   laisser un `FutureBuilder` en attente indéfinie ;
/// - [_getWithRetry] centralise la politique de nouvelle tentative pour que
///   toutes les méthodes publiques en bénéficient de la même façon.
class UsersApi {
  UsersApi({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'dummyjson.com';
  static const _timeout = Duration(seconds: 8);
  static const _maxAttempts = 3;

  final http.Client _client;

  /// Journal des requêtes émises, à des fins pédagogiques et de débogage :
  /// la partie C exige de pouvoir observer le nombre d'appels réellement
  /// déclenchés (piège du `FutureBuilder` recréé) ainsi que l'espacement
  /// des nouvelles tentatives. Conservé en mémoire, affiché à l'écran par
  /// [RequestLogScreen] et imprimé en console.
  static final List<String> requestLog = [];

  static void _log(String message) {
    final horodatage = DateTime.now().toIso8601String();
    final ligne = '[$horodatage] $message';
    requestLog.add(ligne);
    dev.log(ligne, name: 'UsersApi');
  }

  /// Ferme le client HTTP sous-jacent. Doit être appelé depuis le
  /// `dispose()` de l'état qui possède cette instance ; sans cet appel, les
  /// connexions TCP maintenues ouvertes par `http.Client` ne sont jamais
  /// libérées explicitement.
  void dispose() {
    _client.close();
  }

  Future<UsersPage> fetchUsers({int limit = 20, int skip = 0, int? delayMs}) {
    final params = {
      'limit': '$limit',
      'skip': '$skip',
      'select': 'firstName,lastName,email,image,company',
      if (delayMs != null) 'delay': '$delayMs',
    };
    final uri = Uri.https(_host, '/users', params);
    return _fetchPage(uri);
  }

  Future<UsersPage> searchUsers(String query, {int limit = 20, int skip = 0}) {
    final uri = Uri.https(_host, '/users/search', {
      'q': query,
      'limit': '$limit',
      'skip': '$skip',
    });
    return _fetchPage(uri);
  }

  Future<ParticipantDetail> fetchUserDetail(int id) async {
    final uri = Uri.https(_host, '/users/$id');
    final response = await _getWithRetry(uri);
    final json = _decodeMap(response.body);
    return ParticipantDetail.fromJson(json);
  }

  /// Point d'entrée volontairement nommé « sans mémorisation » : il ne fait
  /// qu'exécuter la requête, sans jamais mémoriser le `Future` obtenu.
  /// Utilisé par [FaultyFutureBuilderDemoScreen] pour donner un exemple
  /// observable du piège du `FutureBuilder` recréé (voir ce fichier).
  Future<UsersPage> fetchFirstPageForDemo() => fetchUsers(limit: 5, skip: 0);

  Future<UsersPage> _fetchPage(Uri uri) async {
    final response = await _getWithRetry(uri);
    // Le décodage JSON et la construction de la liste de participants sont
    // déportés hors du fil principal avec `compute` (voir _parseUsersPage,
    // qui refait sa propre vérification défensive dans l'isolate). Sur une
    // page de 20 éléments l'intérêt est marginal (quelques centaines de
    // microsecondes), mais la même fonction est utilisée pour toutes les
    // tailles de page : le code n'a pas à être réécrit le jour où `limit`
    // augmente sensiblement.
    return compute(_parseUsersPage, response.body);
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const DecodingException(
        'La réponse du serveur est illisible (format inattendu).',
      );
    } on FormatException {
      throw const DecodingException(
        'La réponse du serveur est illisible (JSON invalide).',
      );
    }
  }

  /// Exécute une requête GET avec délai d'expiration explicite et nouvelle
  /// tentative à temporisation croissante, réservée aux erreurs
  /// transitoires (réseau, délai dépassé, 5xx). Un 404 n'est jamais retenté :
  /// répéter une requête vers une ressource qui n'existe pas ne la fera pas
  /// apparaître.
  Future<http.Response> _getWithRetry(Uri uri) async {
    var tentative = 1;
    while (true) {
      _log('GET $uri (tentative $tentative/$_maxAttempts)');
      try {
        final response = await _guarded(
          () => _client.get(uri).timeout(_timeout),
        );
        _verifyStatusCode(response);
        return response;
      } on ApiException catch (erreur) {
        final transitoire = erreur is NetworkException ||
            erreur is TimeoutApiException ||
            erreur is ServerException;
        if (!transitoire || tentative >= _maxAttempts) {
          _log('Échec définitif ($erreur) après $tentative tentative(s)');
          rethrow;
        }
        final delaiSecondes = 1 << (tentative - 1); // 1, puis 2, puis 4
        _log(
          'Erreur transitoire ($erreur) — nouvelle tentative dans '
          '${delaiSecondes}s',
        );
        await Future<void>.delayed(Duration(seconds: delaiSecondes));
        tentative += 1;
      }
    }
  }

  /// Vérifie le code de statut avant tout décodage : c'est la règle
  /// centrale de la partie A. Un corps de réponse d'erreur peut ne pas être
  /// du JSON exploitable ; le décoder avant d'avoir vérifié le code
  /// exposerait un `FormatException` brut plutôt qu'un message compris.
  void _verifyStatusCode(http.Response response) {
    final code = response.statusCode;
    if (code == 200) return;
    if (code == 404) {
      throw const NotFoundException('Cette ressource n\'existe pas.');
    }
    if (code >= 500) {
      throw ServerException(
        'Le service est momentanément indisponible, veuillez réessayer.',
        code,
      );
    }
    throw UnexpectedStatusException(
      'La requête a échoué (code $code).',
      code,
    );
  }
}

/// Traduit les exceptions bas niveau (réseau, délai, format) en exceptions
/// applicatives. Exécuté ici plutôt qu'à l'appel pour que toute méthode
/// passant par `_client.get(...).timeout(...)` bénéficie de la même
/// traduction, quel que soit l'endpoint appelé.
Future<http.Response> _guarded(Future<http.Response> Function() action) async {
  try {
    return await action();
  } on TimeoutException {
    throw const TimeoutApiException(
      'Délai dépassé, le serveur ne répond pas assez vite.',
    );
  } on SocketException {
    throw const NetworkException(
      'Impossible de contacter le serveur, vérifiez votre connexion.',
    );
  } on http.ClientException {
    throw const NetworkException(
      'Impossible de contacter le serveur, vérifiez votre connexion.',
    );
  }
}

/// Exécuté dans un isolate séparé par `compute` : construit la page de
/// participants à partir du corps JSON brut. Ne doit dépendre d'aucun état
/// du widget (règle de `compute`, qui n'accepte que des fonctions
/// top-level ou statiques).
UsersPage _parseUsersPage(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const DecodingException('La réponse du serveur est illisible.');
  }
  final usersJson = decoded['users'];
  final participants = <Participant>[];
  if (usersJson is List) {
    for (final item in usersJson) {
      if (item is Map<String, dynamic>) {
        participants.add(Participant.fromJson(item));
      }
    }
  }
  return UsersPage(
    participants: participants,
    total: ParticipantJsonHelpers.asInt(decoded['total']),
    skip: ParticipantJsonHelpers.asInt(decoded['skip']),
    limit: ParticipantJsonHelpers.asInt(decoded['limit'], fallback: participants.length),
  );
}

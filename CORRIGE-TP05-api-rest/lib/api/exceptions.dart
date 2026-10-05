/// Hiérarchie d'exceptions applicatives.
///
/// Le but est de ne jamais exposer une exception technique brute (message
/// d'un `SocketException`, d'un `FormatException`, ou une pile d'appel) dans
/// l'interface. Chaque sous-type porte un [message] déjà rédigé pour un
/// utilisateur final, et permet à l'appelant de décider s'il doit retenter
/// la requête (voir `RetryPolicy` dans `users_api.dart`).
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Message destiné à l'affichage direct dans l'interface.
  final String message;

  @override
  String toString() => message;
}

/// La requête n'a pas pu atteindre le serveur : coupure réseau, DNS,
/// certificat, ou délai d'expiration dépassé (voir [TimeoutApiException]).
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// Le délai d'expiration explicite de la requête a été dépassé. Distincte de
/// [NetworkException] pour que le message affiché soit spécifique
/// (« délai dépassé » et non un « erreur réseau » générique).
class TimeoutApiException extends ApiException {
  const TimeoutApiException(super.message);
}

/// Le serveur a répondu avec un code 5xx : panne ou surcharge côté serveur,
/// potentiellement transitoire, donc éligible à une nouvelle tentative.
class ServerException extends ApiException {
  const ServerException(super.message, this.statusCode);

  final int statusCode;
}

/// Le serveur a répondu 404 : la ressource demandée n'existe pas. Ce n'est
/// pas une erreur transitoire, une nouvelle tentative est donc inutile et
/// même trompeuse (l'utilisateur croirait à un problème réseau).
class NotFoundException extends ApiException {
  const NotFoundException(super.message);
}

/// Le corps de la réponse n'a pas pu être décodé en JSON, ou sa forme ne
/// correspond pas à ce qui était attendu (clé absente à un endroit
/// structurant, type radicalement incompatible). Ne doit normalement pas se
/// produire avec l'API imposée, mais protège contre une évolution du
/// contrat de l'API ou une réponse HTML renvoyée par erreur (page de
/// maintenance d'un proxy, par exemple).
class DecodingException extends ApiException {
  const DecodingException(super.message);
}

/// Le serveur a répondu avec un autre code d'erreur (4xx hors 404), non
/// couvert par une catégorie plus spécifique.
class UnexpectedStatusException extends ApiException {
  const UnexpectedStatusException(super.message, this.statusCode);

  final int statusCode;
}

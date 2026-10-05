// Script de vérification exécuté avec `dart run verification_decodage.dart`.
//
// Il n'est PAS livré comme partie de l'application (les écrans ne l'importent
// pas) : c'est une preuve, à l'intention du formateur, que Participant.fromJson
// et ParticipantDetail.fromJson décodent réellement la réponse de production
// de DummyJSON sans lever d'exception, et que les quatre cas limites imposés
// par l'énoncé (absent, null, type inattendu, sous-objet manquant) sont bien
// tolérés. Conservé à la racine du projet, hors de lib/, précisément pour ne
// pas être confondu avec du code applicatif.
import 'dart:convert';
import 'dart:io';

import 'lib/models/participant.dart';
import 'lib/models/participant_detail.dart';

Future<void> main() async {
  var echecs = 0;

  void verifier(String intitule, bool condition) {
    final statut = condition ? 'OK' : 'ECHEC';
    if (!condition) echecs += 1;
    stdout.writeln('[$statut] $intitule');
  }

  stdout.writeln('--- 1. Liste réelle (/users?limit=2&select=...) ---');
  final httpClient = HttpClient();
  final reponseListe = await _get(
    httpClient,
    'https://dummyjson.com/users?limit=2&skip=0&select=firstName,lastName,email,image,company',
  );
  final jsonListe = jsonDecode(reponseListe) as Map<String, dynamic>;
  final usersJson = (jsonListe['users'] as List).cast<Map<String, dynamic>>();
  final participants = usersJson.map(Participant.fromJson).toList();
  verifier('2 participants décodés depuis la réponse réelle', participants.length == 2);
  verifier('total présent dans la réponse réelle', jsonListe['total'] is int);
  verifier(
    'company.name imbriqué correctement extrait (${participants.first.companyName})',
    participants.first.companyName.isNotEmpty,
  );
  verifier(
    'email non vide sur le premier utilisateur réel',
    participants.first.email.contains('@'),
  );

  stdout.writeln('\n--- 2. Détail réel (/users/5) ---');
  final reponseDetail = await _get(httpClient, 'https://dummyjson.com/users/5');
  final detail = ParticipantDetail.fromJson(
    jsonDecode(reponseDetail) as Map<String, dynamic>,
  );
  verifier('id=5 décodé correctement', detail.id == 5);
  verifier('téléphone présent (${detail.phone})', detail.phone.isNotEmpty);
  verifier('adresse recomposée (${detail.address})', detail.address.isNotEmpty);

  stdout.writeln('\n--- 3. Recherche réelle (/users/search?q=Emily) ---');
  final reponseRecherche = await _get(
    httpClient,
    'https://dummyjson.com/users/search?q=Emily&limit=3',
  );
  final jsonRecherche = jsonDecode(reponseRecherche) as Map<String, dynamic>;
  final resultats = (jsonRecherche['users'] as List)
      .cast<Map<String, dynamic>>()
      .map(Participant.fromJson)
      .toList();
  verifier('résultats de recherche décodés (${resultats.length})', resultats.isNotEmpty);
  verifier(
    'chaque résultat contient bien "Emily"',
    resultats.every((p) => p.firstName.toLowerCase().contains('emily')),
  );

  stdout.writeln('\n--- 4. Erreur serveur réelle (/http/500) ---');
  final codeErreur = await _getStatusCode(httpClient, 'https://dummyjson.com/http/500');
  verifier('code 500 bien renvoyé par le serveur réel', codeErreur == 500);

  stdout.writeln('\n--- 5. Cas limites simulés localement (JSON de test, PAS l\'API réelle) ---');

  // Champ absent.
  final sansEmail = Participant.fromJson({
    'id': 1,
    'firstName': 'Test',
    'lastName': 'Sans-email',
  });
  verifier('champ "email" absent -> chaîne vide sans exception', sansEmail.email == '');

  // Champ présent mais null.
  final champsNuls = Participant.fromJson({
    'id': null,
    'firstName': null,
    'lastName': null,
    'email': null,
    'image': null,
    'company': null,
  });
  verifier('tous les champs nuls -> valeurs de repli, id=0', champsNuls.id == 0);
  verifier('tous les champs nuls -> companyName de repli', champsNuls.companyName == 'Non renseigné');

  // Nombre reçu sous forme de chaîne.
  final idEnChaine = Participant.fromJson({
    'id': '5',
    'firstName': 'Test',
    'lastName': 'Id-string',
  });
  verifier('"id": "5" (chaîne) converti en entier 5', idEnChaine.id == 5);

  // Sous-objet company absent de "name".
  final companySansName = Participant.fromJson({
    'id': 9,
    'firstName': 'Test',
    'lastName': 'Company-sans-name',
    'company': {'department': 'RH'},
  });
  verifier(
    'company sans "name" -> repli "Non renseigné"',
    companySansName.companyName == 'Non renseigné',
  );

  // Sous-objet company absent entièrement.
  final sansCompany = Participant.fromJson({
    'id': 10,
    'firstName': 'Test',
    'lastName': 'Sans-company',
  });
  verifier('company absent -> repli "Non renseigné"', sansCompany.companyName == 'Non renseigné');

  // Type radicalement inattendu (company est une chaîne, pas une Map).
  final companyMalType = Participant.fromJson({
    'id': 11,
    'firstName': 'Test',
    'lastName': 'Company-mal-type',
    'company': 'ceci-n-est-pas-un-objet',
  });
  verifier(
    'company de type chaîne (pas Map) -> repli sans exception',
    companyMalType.companyName == 'Non renseigné',
  );

  httpClient.close(force: true);

  stdout.writeln('\n=== Résultat global : ${echecs == 0 ? "TOUT EST PASSÉ" : "$echecs ÉCHEC(S)"} ===');
  if (echecs > 0) exit(1);
}

Future<String> _get(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  return response.transform(utf8.decoder).join();
}

Future<int> _getStatusCode(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  await response.drain<void>();
  return response.statusCode;
}

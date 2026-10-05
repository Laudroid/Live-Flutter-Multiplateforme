import 'package:flutter/material.dart';

import '../api/exceptions.dart';
import '../api/users_api.dart';
import '../models/participant.dart';
import '../widgets/participant_tile.dart';
import 'faulty_future_builder_screen.dart';
import 'participant_detail_screen.dart';
import 'request_log_screen.dart';

/// États d'affichage possibles de la liste, au-delà des trois branches
/// standard du FutureBuilder (attente / erreur / données) : la partie B
/// exige de distinguer une recherche sans résultat (liste vide, code 200)
/// d'une erreur réseau ou serveur. Une [UsersPage] avec une liste vide n'est
/// pas une erreur ; il faut donc porter cette distinction dans le résultat
/// lui-même plutôt que dans une exception.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  // Une seule instance de client HTTP pour tout l'écran (et pour l'écran de
  // détail, auquel elle est transmise) : voir la justification dans
  // UsersApi et dans le README (réutilisation de connexion).
  final UsersApi _api = UsersApi();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // --- Mémorisation du Future : le piège central de la partie C ---
  //
  // _futurePage n'est JAMAIS affecté depuis build(). Il est créé une seule
  // fois dans initState, puis réaffecté uniquement en réponse à une action
  // explicite de l'utilisateur (tirer pour rafraîchir, lancer une
  // recherche, charger la page suivante), toujours à l'intérieur d'un
  // setState. Un FutureBuilder(future: _api.fetchUsers(), ...) écrit
  // directement dans build() relancerait la requête à chaque recomposition
  // du widget, y compris pour des raisons sans rapport avec les données
  // (rotation, clavier, setState d'un widget frère). La démonstration de ce
  // défaut, provoqué volontairement, se trouve dans
  // faulty_future_builder_screen.dart.
  late Future<UsersPage> _futurePage;

  final List<Participant> _participants = [];
  int _total = 0;
  int _skip = 0;
  static const _pageSize = 20;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _activeQuery;

  @override
  void initState() {
    super.initState();
    _futurePage = _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  /// Charge la première page (skip=0), qu'il s'agisse du chargement initial,
  /// d'une nouvelle recherche ou d'un rafraîchissement par tirage. Remet
  /// systématiquement l'état de pagination à zéro pour ne jamais mélanger
  /// une ancienne liste avec de nouvelles pages.
  Future<UsersPage> _loadFirstPage() async {
    _participants.clear();
    _skip = 0;
    _hasMore = true;
    final page = _activeQuery == null
        ? await _api.fetchUsers(limit: _pageSize, skip: 0)
        : await _api.searchUsers(_activeQuery!, limit: _pageSize, skip: 0);
    _participants.addAll(page.participants);
    _total = page.total;
    _skip = page.skip + page.participants.length;
    _hasMore = page.hasMore;
    return page;
  }

  Future<void> _onRefresh() async {
    setState(() {
      _futurePage = _loadFirstPage();
    });
    // RefreshIndicator attend un Future : on lui fournit celui déjà
    // mémorisé, sans en démarrer un second en parallèle.
    await _futurePage;
  }

  void _lancerRecherche(String motCle) {
    final motNettoye = motCle.trim();
    setState(() {
      _activeQuery = motNettoye.isEmpty ? null : motNettoye;
      _futurePage = _loadFirstPage();
    });
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    // Anticipation raisonnable : on déclenche le chargement suivant avant
    // d'atteindre le bas visible, à l'approche des trois derniers éléments
    // (approximé ici via une marge de 400px avant le bas du scroll).
    final seuil = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= seuil) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = _activeQuery == null
          ? await _api.fetchUsers(limit: _pageSize, skip: _skip)
          : await _api.searchUsers(_activeQuery!, limit: _pageSize, skip: _skip);
      if (!mounted) return;
      setState(() {
        _participants.addAll(page.participants);
        _total = page.total;
        _skip = page.skip + page.participants.length;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      // Un échec de chargement de page suivante ne doit pas effacer la
      // liste déjà affichée : on se contente de réarmer l'indicateur de
      // pied de liste pour permettre une nouvelle tentative au prochain
      // défilement.
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annuaire — Event Planner'),
        actions: [
          IconButton(
            tooltip: 'Démo pédagogique — piège du FutureBuilder',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FaultyFutureBuilderDemoScreen(api: _api),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Journal des requêtes (démo pédagogique)',
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RequestLogScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _BarreDeRecherche(
            controller: _searchController,
            onSubmitted: _lancerRecherche,
            onClear: () {
              _searchController.clear();
              _lancerRecherche('');
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: FutureBuilder<UsersPage>(
                future: _futurePage,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _EtatErreur(erreur: snapshot.error);
                  }
                  if (_participants.isEmpty) {
                    // État vide, distinct de l'état d'erreur : code 200,
                    // liste simplement vide (recherche sans résultat).
                    return _EtatVide(recherche: _activeQuery);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _participants.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _participants.length) {
                        return _PiedDeListe(
                          isLoading: _isLoadingMore,
                          hasMore: _hasMore,
                          total: _total,
                          charges: _participants.length,
                        );
                      }
                      final participant = _participants[index];
                      return ParticipantTile(
                        participant: participant,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ParticipantDetailScreen(
                              userId: participant.id,
                              api: _api,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarreDeRecherche extends StatelessWidget {
  const _BarreDeRecherche({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        // Champ de saisie minimal, sans Form ni validation : la validation
        // de formulaire appartient à la séance 6, hors périmètre de ce TP.
        decoration: InputDecoration(
          hintText: 'Rechercher un participant (ex. Emily)',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _EtatErreur extends StatelessWidget {
  const _EtatErreur({required this.erreur});

  final Object? erreur;

  @override
  Widget build(BuildContext context) {
    final message = erreur is ApiException
        ? (erreur as ApiException).message
        : 'Une erreur inattendue est survenue, veuillez réessayer.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.red.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  const _EtatVide({required this.recherche});

  final String? recherche;

  @override
  Widget build(BuildContext context) {
    final message = recherche == null
        ? 'Aucun participant à afficher.'
        : 'Aucun résultat pour « $recherche ».';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Indicateur de pied de liste : visuellement distinct du chargement plein
/// écran de la première page (un simple `CircularProgressIndicator` de
/// petite taille, sans masquer les éléments déjà chargés) et informatif une
/// fois la pagination terminée (compteur « X / total »).
class _PiedDeListe extends StatelessWidget {
  const _PiedDeListe({
    required this.isLoading,
    required this.hasMore,
    required this.total,
    required this.charges,
  });

  final bool isLoading;
  final bool hasMore;
  final int total;
  final int charges;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '$charges / $total participants chargés — fin de la liste',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

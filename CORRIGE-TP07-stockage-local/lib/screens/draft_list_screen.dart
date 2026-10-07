import 'package:flutter/material.dart';

import '../storage/draft_repository.dart';
import '../utils/file_size_format.dart';
import 'draft_edit_screen.dart';

/// Liste tous les brouillons présents sur le disque : titre, date de
/// dernière sauvegarde et taille occupée. Permet la suppression
/// individuelle et globale.
class DraftListScreen extends StatefulWidget {
  const DraftListScreen({super.key, required this.repository});

  final DraftRepository repository;

  @override
  State<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends State<DraftListScreen> {
  late Future<List<DraftSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.listDrafts();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.listDrafts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brouillons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Tout supprimer',
            onPressed: () async {
              await widget.repository.deleteAll();
              _reload();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DraftSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final drafts = snapshot.data ?? const [];
          if (drafts.isEmpty) {
            return const Center(child: Text('Aucun brouillon.'));
          }
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                title: Text(draft.displayTitle),
                subtitle: Text(
                  '${draft.updatedAt.toLocal()} · ${formatFileSize(draft.sizeBytes)}',
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DraftEditScreen(
                        repository: widget.repository,
                        draftId: draft.id,
                      ),
                    ),
                  );
                  _reload();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await widget.repository.deleteDraft(draft.id);
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newId = DateTime.now().microsecondsSinceEpoch.toString();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DraftEditScreen(
                repository: widget.repository,
                draftId: newId,
              ),
            ),
          );
          _reload();
        },
      ),
    );
  }
}

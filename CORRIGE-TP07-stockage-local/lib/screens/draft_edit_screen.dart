import 'package:flutter/material.dart';

import '../models/event_draft.dart';
import '../storage/draft_lifecycle_observer.dart';
import '../storage/draft_repository.dart';

/// Écran d'édition d'un brouillon. Saisie minimale (`TextField` simple,
/// sans `Form`/`TextFormField` ni validation évaluée, conformément au
/// périmètre du TP).
///
/// Sauvegarde automatique sur passage en arrière-plan : un
/// [DraftLifecycleObserver] est enregistré dans `initState` et retiré dans
/// `dispose`.
class DraftEditScreen extends StatefulWidget {
  const DraftEditScreen({
    super.key,
    required this.repository,
    required this.draftId,
  });

  final DraftRepository repository;
  final String draftId;

  @override
  State<DraftEditScreen> createState() => _DraftEditScreenState();
}

class _DraftEditScreenState extends State<DraftEditScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _reminderEnabled = false;
  DraftLoadStatus? _loadStatus;
  late final DraftLifecycleObserver _observer;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _observer = DraftLifecycleObserver(onSaveRequested: _save);
    WidgetsBinding.instance.addObserver(_observer);
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final result = await widget.repository.loadDraft(widget.draftId);
    _loadStatus = result.status;
    final draft = result.draft ?? EventDraft.empty(widget.draftId);
    _titleController.text = draft.title;
    _locationController.text = draft.location;
    _categoryController.text = draft.category;
    _reminderEnabled = draft.reminderEnabled;
  }

  Future<void> _save() async {
    final draft = EventDraft(
      id: widget.draftId,
      title: _titleController.text,
      location: _locationController.text,
      category: _categoryController.text,
      reminderEnabled: _reminderEnabled,
    );
    await widget.repository.saveDraft(draft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    _titleController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brouillon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              await _save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Brouillon sauvegardé.')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loadStatus == DraftLoadStatus.corrupted)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Brouillon illisible : le fichier existant était corrompu '
                    'et a été ignoré. Vous repartez d\'un brouillon vide.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              SwitchListTile(
                title: const Text('Rappel activé'),
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
              ),
            ],
          );
        },
      ),
    );
  }
}

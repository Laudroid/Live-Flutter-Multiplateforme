import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Mise à jour du profil (Partie B.7) : appelle `updateDisplayName` et
/// reflète le nouveau nom dans l'interface après l'opération.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.displayName ?? '',
  );
  bool _isSaving = false;
  String? _confirmation;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _confirmation = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    await user?.updateDisplayName(_nameController.text.trim());
    // updateDisplayName ne met pas à jour `user` en mémoire de façon
    // synchrone sur toutes les plateformes : reload() force la relecture
    // depuis le serveur pour que currentUser?.displayName soit à jour
    // immédiatement dans le reste de l'application (ex. AppBar de
    // OrganizerHomeScreen, alimentée par userChanges()).
    await user?.reload();
    if (mounted) {
      setState(() {
        _isSaving = false;
        _confirmation = 'Nom affiché mis à jour.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Courriel : ${user?.email ?? '(inconnu)'}'),
                Text('UID : ${user?.uid ?? '(inconnu)'}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom affiché',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_confirmation != null) ...[
                  const SizedBox(height: 12),
                  Text(_confirmation!,
                      style: TextStyle(color: Colors.green.shade700)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

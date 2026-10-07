import 'package:flutter/material.dart';

import '../storage/preferences_store.dart';

/// Écran de réglages minimal : un sélecteur par préférence, chacun appelant
/// directement un setter typé de [PreferencesStore]. Aucun appel à
/// `shared_preferences` ici : l'écran ignore tout de l'implémentation.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final PreferencesStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Thème'),
            trailing: DropdownButton<AppThemeMode>(
              value: store.themeMode,
              items: const [
                DropdownMenuItem(value: AppThemeMode.light, child: Text('Clair')),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('Sombre')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await store.setThemeMode(value);
                setState(() {});
              },
            ),
          ),
          ListTile(
            title: const Text('Tri par défaut'),
            trailing: DropdownButton<EventSortOrder>(
              value: store.defaultSort,
              items: const [
                DropdownMenuItem(value: EventSortOrder.date, child: Text('Date')),
                DropdownMenuItem(value: EventSortOrder.title, child: Text('Titre')),
                DropdownMenuItem(
                  value: EventSortOrder.popularity,
                  child: Text('Popularité'),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await store.setDefaultSort(value);
                setState(() {});
              },
            ),
          ),
          ListTile(
            title: const Text('Catégorie filtrée par défaut'),
            trailing: SizedBox(
              width: 160,
              child: TextField(
                controller: TextEditingController(text: store.defaultCategoryFilter)
                  ..selection = TextSelection.collapsed(
                    offset: store.defaultCategoryFilter.length,
                  ),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(hintText: 'aucun filtre'),
                onSubmitted: (value) async {
                  await store.setDefaultCategoryFilter(value);
                  setState(() {});
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Densité d\'affichage'),
            trailing: DropdownButton<DisplayDensity>(
              value: store.displayDensity,
              items: const [
                DropdownMenuItem(
                  value: DisplayDensity.comfortable,
                  child: Text('Confortable'),
                ),
                DropdownMenuItem(
                  value: DisplayDensity.compact,
                  child: Text('Compacte'),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await store.setDisplayDensity(value);
                setState(() {});
              },
            ),
          ),
          ListTile(
            title: const Text('Dernier écran consulté'),
            subtitle: Text(store.lastScreen),
          ),
        ],
      ),
    );
  }
}

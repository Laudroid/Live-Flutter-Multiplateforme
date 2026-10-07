import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'screens/draft_list_screen.dart';
import 'screens/settings_screen.dart';
import 'storage/draft_repository.dart';
import 'storage/preferences_store.dart';

Future<void> main() async {
  // `await` avant `runApp` plutôt qu'un `FutureBuilder` racine : le choix
  // est documenté en une phrase dans README.md. `WidgetsFlutterBinding` doit
  // être initialisé explicitement puisque du code asynchrone (accès plugin)
  // s'exécute avant `runApp`.
  WidgetsFlutterBinding.ensureInitialized();

  final preferencesStore = SharedPreferencesStore();
  await preferencesStore.init();

  final documentsDir = await getApplicationDocumentsDirectory();
  final draftsDir = Directory('${documentsDir.path}/drafts');
  final draftRepository = DraftRepository(draftsDir);

  runApp(EventPlannerStorageApp(
    preferencesStore: preferencesStore,
    draftRepository: draftRepository,
  ));
}

class EventPlannerStorageApp extends StatelessWidget {
  const EventPlannerStorageApp({
    super.key,
    required this.preferencesStore,
    required this.draftRepository,
  });

  final PreferencesStore preferencesStore;
  final DraftRepository draftRepository;

  @override
  Widget build(BuildContext context) {
    final isDark = preferencesStore.themeMode == AppThemeMode.dark;
    return MaterialApp(
      title: 'TP7 — Stockage local',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: HomeTabs(
        preferencesStore: preferencesStore,
        draftRepository: draftRepository,
      ),
    );
  }
}

/// Point d'entrée avec deux onglets : réglages (Partie A) et brouillons
/// (Partie B). Pas de `provider` ni d'état global partagé entre écrans :
/// les deux instances (`preferencesStore`, `draftRepository`) sont
/// construites une fois dans `main()` et transmises par constructeur.
class HomeTabs extends StatefulWidget {
  const HomeTabs({
    super.key,
    required this.preferencesStore,
    required this.draftRepository,
  });

  final PreferencesStore preferencesStore;
  final DraftRepository draftRepository;

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DraftListScreen(repository: widget.draftRepository),
      SettingsScreen(store: widget.preferencesStore),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) async {
          setState(() => _index = value);
          await widget.preferencesStore.setLastScreen(
            value == 0 ? 'drafts' : 'settings',
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Brouillons'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Réglages'),
        ],
      ),
    );
  }
}

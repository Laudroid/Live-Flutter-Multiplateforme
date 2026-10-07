import 'package:shared_preferences/shared_preferences.dart';

import 'preference_keys.dart';

/// Thème d'affichage choisi par l'utilisateur.
enum AppThemeMode { light, dark }

/// Ordre de tri par défaut appliqué à la liste des événements.
enum EventSortOrder { date, title, popularity }

/// Densité d'affichage des listes.
enum DisplayDensity { comfortable, compact }

/// Interface métier des préférences. Aucun écran ne doit importer
/// `shared_preferences` directement : tout passe par ces méthodes typées,
/// jamais par des chaînes ou des `getString`/`setString` bruts exposés à
/// l'appelant.
abstract class PreferencesStore {
  /// Doit être attendu (`await`) avant toute lecture des accesseurs
  /// synchrones ci-dessous (`themeMode`, `defaultSort`, etc.).
  Future<void> init();

  AppThemeMode get themeMode;
  Future<void> setThemeMode(AppThemeMode mode);

  EventSortOrder get defaultSort;
  Future<void> setDefaultSort(EventSortOrder order);

  String get defaultCategoryFilter; // '' = aucun filtre
  Future<void> setDefaultCategoryFilter(String category);

  DisplayDensity get displayDensity;
  Future<void> setDisplayDensity(DisplayDensity density);

  String get lastScreen;
  Future<void> setLastScreen(String screenName);
}

/// Implémentation concrète reposant sur `SharedPreferencesWithCache`.
///
/// Choix documenté (voir aussi README.md) : les cinq préférences de ce TP
/// sont lues à *chaque construction d'écran* (thème dans le `MaterialApp`,
/// tri et filtre dans la liste d'événements, densité dans chaque item,
/// dernier écran au démarrage). L'interface `PreferencesStore` expose des
/// accesseurs *synchrones* (`get themeMode`, etc.) — imposés par l'énoncé —
/// ce qui exclut `SharedPreferencesAsync`, dont les lectures sont toujours
/// asynchrones. `SharedPreferencesWithCache` répond exactement à ce besoin :
/// une seule initialisation asynchrone (`init`), puis des lectures
/// synchrones depuis le cache local, sans interroger la plateforme à
/// chaque `build()`. Le coût d'un rechargement explicite (`reloadCache`)
/// est accepté car ce processus est seul propriétaire de ces clés : aucune
/// autre isolate ou processus ne les modifie en dehors des setters de cette
/// classe, donc le cache ne peut pas devenir silencieusement obsolète.
///
/// Contrainte documentée par l'énoncé : les accesseurs synchrones supposent
/// que [init] a déjà été appelé et complété (attendu avant `runApp`). Les
/// appeler avant lève une exception explicite plutôt que de retourner une
/// valeur incohérente.
class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesWithCache? _cache;

  SharedPreferencesWithCache get _requireCache {
    final cache = _cache;
    if (cache == null) {
      throw StateError(
        'PreferencesStore.init() doit être attendu avant toute lecture.',
      );
    }
    return cache;
  }

  @override
  Future<void> init() async {
    _cache = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: PreferenceKeys.all,
      ),
    );
  }

  @override
  AppThemeMode get themeMode {
    final raw = _requireCache.getString(PreferenceKeys.themeMode);
    return raw == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) {
    return _requireCache.setString(
      PreferenceKeys.themeMode,
      mode == AppThemeMode.dark ? 'dark' : 'light',
    );
  }

  @override
  EventSortOrder get defaultSort {
    final raw = _requireCache.getString(PreferenceKeys.defaultSort);
    switch (raw) {
      case 'title':
        return EventSortOrder.title;
      case 'popularity':
        return EventSortOrder.popularity;
      default:
        return EventSortOrder.date;
    }
  }

  @override
  Future<void> setDefaultSort(EventSortOrder order) {
    return _requireCache.setString(PreferenceKeys.defaultSort, order.name);
  }

  @override
  String get defaultCategoryFilter {
    return _requireCache.getString(PreferenceKeys.defaultCategoryFilter) ??
        '';
  }

  @override
  Future<void> setDefaultCategoryFilter(String category) {
    return _requireCache.setString(
      PreferenceKeys.defaultCategoryFilter,
      category,
    );
  }

  @override
  DisplayDensity get displayDensity {
    final raw = _requireCache.getString(PreferenceKeys.displayDensity);
    return raw == 'compact' ? DisplayDensity.compact : DisplayDensity.comfortable;
  }

  @override
  Future<void> setDisplayDensity(DisplayDensity density) {
    return _requireCache.setString(
      PreferenceKeys.displayDensity,
      density == DisplayDensity.compact ? 'compact' : 'comfortable',
    );
  }

  @override
  String get lastScreen {
    return _requireCache.getString(PreferenceKeys.lastScreen) ?? 'home';
  }

  @override
  Future<void> setLastScreen(String screenName) {
    return _requireCache.setString(PreferenceKeys.lastScreen, screenName);
  }
}

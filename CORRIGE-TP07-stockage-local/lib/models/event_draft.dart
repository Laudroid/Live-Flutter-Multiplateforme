/// Version courante du schéma de sérialisation d'un [EventDraft].
///
/// Historique :
/// - version 1 : champs `id`, `title`, `city`, `date`, `category`,
///   `updatedAt`.
/// - version 2 : `city` est renommé `location` ; ajout de `reminderEnabled`
///   (valeur par défaut `false` pour les brouillons écrits en version 1).
const int currentDraftSchemaVersion = 2;

/// Brouillon d'événement partiellement rempli, persistant sur disque.
///
/// `toJson`/`fromJson` sont écrits à la main (pas de génération de code),
/// comme l'impose l'énoncé. `fromJson` assure la migration transparente
/// d'un fichier écrit par un ancien schéma (version 1) vers le modèle
/// courant : c'est la seule fonction qui a connaissance de l'historique du
/// schéma, le reste de l'application ne manipule que la forme courante.
class EventDraft {
  EventDraft({
    required this.id,
    this.title = '',
    this.location = '',
    this.date,
    this.category = '',
    this.reminderEnabled = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final String location;
  final DateTime? date;
  final String category;
  final bool reminderEnabled;
  final DateTime updatedAt;

  /// Un brouillon vide (identifiant connu, aucun champ rempli). Utilisé
  /// quand l'écran d'édition s'ouvre sur un identifiant inconnu ou sur un
  /// fichier absent/vide : jamais d'exception remontée à l'utilisateur.
  factory EventDraft.empty(String id) => EventDraft(id: id);

  EventDraft copyWith({
    String? title,
    String? location,
    DateTime? date,
    String? category,
    bool? reminderEnabled,
  }) {
    return EventDraft(
      id: id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      category: category ?? this.category,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty =>
      title.isEmpty && location.isEmpty && date == null && category.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': currentDraftSchemaVersion,
      'id': id,
      'title': title,
      'location': location,
      'date': date?.toIso8601String(),
      'category': category,
      'reminderEnabled': reminderEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Reconstruit un [EventDraft] depuis un JSON déjà décodé, quel que soit
  /// le `schemaVersion` rencontré (1 ou 2). La migration se limite à cette
  /// fonction : un champ absent (`schemaVersion` manquant, brouillon très
  /// ancien) est traité comme la version 1.
  factory EventDraft.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;

    // Migration version 1 -> 2 : `city` devient `location`, et
    // `reminderEnabled` est ajouté avec la valeur par défaut `false`.
    final String location;
    if (schemaVersion >= 2) {
      location = json['location'] as String? ?? '';
    } else {
      location = json['city'] as String? ?? '';
    }
    final bool reminderEnabled =
        schemaVersion >= 2 ? (json['reminderEnabled'] as bool? ?? false) : false;

    final rawDate = json['date'] as String?;
    final rawUpdatedAt = json['updatedAt'] as String?;

    return EventDraft(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      location: location,
      date: rawDate == null ? null : DateTime.tryParse(rawDate),
      category: json['category'] as String? ?? '',
      reminderEnabled: reminderEnabled,
      updatedAt: rawUpdatedAt == null
          ? DateTime.now()
          : (DateTime.tryParse(rawUpdatedAt) ?? DateTime.now()),
    );
  }
}

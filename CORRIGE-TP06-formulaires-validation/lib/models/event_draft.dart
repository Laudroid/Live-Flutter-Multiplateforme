import 'package:flutter/material.dart' show TimeOfDay;

/// Modèle immuable et typé produit par la soumission du formulaire de
/// création d'événement (Partie B). Volontairement construit avec `const` et
/// des champs `final` : une fois créée, une instance ne peut plus être
/// modifiée en place, ce qui garantit qu'elle représente fidèlement l'état du
/// formulaire au moment de la confirmation, indépendamment des contrôleurs
/// qui ont servi à la saisir.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.capacity,
    required this.isOnline,
    required this.address,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.price,
    required this.isFree,
  });

  final String title;
  final String description;
  final String category;
  final int capacity;
  final bool isOnline;
  final String? address; // null si isOnline == true
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final double price; // 0 si isFree == true
  final bool isFree;
}

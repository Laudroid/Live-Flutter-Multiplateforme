/// Formatage de date « fait maison », sans dépendance externe.
///
/// L'énoncé exclut explicitement `intl` pour ce TP : cette fonction pure
/// prend un [DateTime] et retourne une chaîne du type
/// « ven. 12 juin, 18h30 ». Étant une fonction pure (aucun effet de bord,
/// aucun accès au contexte Flutter), elle est trivialement testable en
/// dehors de l'arbre de widgets.
String formatEventDate(DateTime date) {
  const weekdays = <String>[
    'lun.',
    'mar.',
    'mer.',
    'jeu.',
    'ven.',
    'sam.',
    'dim.',
  ];
  const months = <String>[
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$weekday ${date.day} $month, ${hour}h$minute';
}

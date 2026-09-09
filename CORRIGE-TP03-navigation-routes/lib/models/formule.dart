/// Formule de participation à un événement (Partie B).
///
/// Trois formules codées en dur, choisies par bouton/carte : l'énoncé
/// interdit tout champ de texte pour cette saisie.
class Formule {
  const Formule({
    required this.id,
    required this.label,
    required this.description,
    required this.tarifEuros,
  });

  final String id;
  final String label;
  final String description;
  final double tarifEuros;
}

const List<Formule> formulesDisponibles = <Formule>[
  Formule(
    id: 'standard',
    label: 'Standard',
    description: 'Accès à l\'événement, placement libre.',
    tarifEuros: 25,
  ),
  Formule(
    id: 'essentiel',
    label: 'Essentiel',
    description: 'Accès + vestiaire + une boisson offerte.',
    tarifEuros: 45,
  ),
  Formule(
    id: 'vip',
    label: 'VIP',
    description: 'Accès prioritaire, espace lounge, cocktail dînatoire.',
    tarifEuros: 89,
  ),
];

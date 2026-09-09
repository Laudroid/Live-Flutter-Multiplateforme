/// Constantes d'espacement et de rayons centralisées.
///
/// L'énoncé (partie C, critère « Propreté ») interdit toute valeur
/// numérique magique répétée pour les marges, paddings et rayons : tout
/// passe par cette classe. Les tailles qui ne sont pas des espacements ou
/// des rayons génériques mais des dimensions propres à un widget précis
/// (par ex. le diamètre de la vignette d'`EventCard`) restent définies au
/// plus près de leur widget, car les déplacer ici n'apporterait aucune
/// réutilisation réelle et éloignerait la constante de son usage.
class Spacing {
  const Spacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  /// Épaisseur standard des bordures fines (cartes, séparateurs de pastille).
  static const double hairline = 1;
}

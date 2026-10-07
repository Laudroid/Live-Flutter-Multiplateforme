/// Formate une taille de fichier en octets vers une chaîne lisible (o, kio).
///
/// Choix : unité binaire (kio = 1024 octets) car c'est ce que rapporte
/// `File.length()` et `FileStat.size`, sans conversion décimale trompeuse.
String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes o';
  }
  final kio = bytes / 1024;
  return '${kio.toStringAsFixed(1)} kio';
}

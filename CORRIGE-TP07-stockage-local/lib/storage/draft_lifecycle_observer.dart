import 'dart:async';

import 'package:flutter/widgets.dart';

/// Observateur de cycle de vie déclenchant une sauvegarde automatique du
/// brouillon en cours d'édition.
///
/// Déclenchement retenu : `AppLifecycleState.paused` plutôt que
/// `inactive`. `inactive` est atteint très fréquemment et brièvement (par
/// exemple lors de l'affichage d'une boîte de dialogue système ou du
/// changement de fenêtre sur certaines plateformes) sans que l'application
/// quitte réellement le premier plan ; déclencher une écriture disque à
/// chaque `inactive` serait un gaspillage et, en Partie C, augmenterait
/// inutilement la fréquence d'écritures que la politique de purge devrait
/// ensuite compenser. `paused` signale que l'application n'est plus du
/// tout visible : c'est le moment pertinent pour persister, juste avant un
/// éventuel arrêt du processus par le système.
class DraftLifecycleObserver extends WidgetsBindingObserver {
  DraftLifecycleObserver({required this.onSaveRequested});

  final Future<void> Function() onSaveRequested;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // L'appel n'est pas attendu ici : `didChangeAppLifecycleState` est
      // synchrone et le système peut suspendre l'exécution juste après son
      // retour. On lance l'écriture sans bloquer le callback ; la
      // combinaison écriture atomique + petite taille de fichier rend ce
      // compromis acceptable pour ce TP.
      unawaited(onSaveRequested());
    }
  }
}

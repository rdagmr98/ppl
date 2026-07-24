import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quando mostrare la spiegazione durante il quiz.
enum ExplanationMode {
  always, // sempre, anche su risposta giusta
  wrongOnly, // solo su risposta sbagliata (comportamento storico)
  flash; // mai: avanza subito, anche su risposta sbagliata

  String get label => switch (this) {
        ExplanationMode.always => 'Sempre',
        ExplanationMode.wrongOnly => 'Se sbagliata',
        ExplanationMode.flash => 'Flash',
      };

  String get description => switch (this) {
        ExplanationMode.always => 'Sempre visibile',
        ExplanationMode.wrongOnly => 'Solo se sbagli',
        ExplanationMode.flash => 'Avanza subito',
      };
}

/// Preferenza persistita (shared_preferences) su quando mostrare le
/// spiegazioni. Caricata una volta all'avvio in [load] e tenuta in un
/// [ValueNotifier] cosi la UI si aggiorna subito senza rileggere i prefs.
class SettingsService {
  static const _key = 'explanation_mode_v1';
  static final ValueNotifier<ExplanationMode> mode =
      ValueNotifier(ExplanationMode.wrongOnly);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key);
    if (raw != null && raw >= 0 && raw < ExplanationMode.values.length) {
      mode.value = ExplanationMode.values[raw];
    }
  }

  static Future<void> setMode(ExplanationMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, m.index);
  }
}

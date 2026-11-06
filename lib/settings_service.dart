import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quando mostrare la spiegazione durante il quiz.
enum ExplanationMode {
  always, // sempre, anche su risposta giusta
  wrongOnly, // solo su risposta sbagliata (comportamento storico)
  flash; // mai: avanza subito, anche su risposta sbagliata

  String get label => switch (this) {
        ExplanationMode.always => 'Spiegazioni sempre visibili',
        ExplanationMode.wrongOnly => 'Spiegazioni solo se sbagli',
        ExplanationMode.flash => 'Spiegazioni disattivate (avanza subito)',
      };

  String get description => switch (this) {
        ExplanationMode.always => 'Spiegazioni: sempre',
        ExplanationMode.wrongOnly => 'Spiegazioni: se sbagli',
        ExplanationMode.flash => 'Spiegazioni: mai',
      };
}

/// Preferenza persistita (shared_preferences) su quando mostrare le
/// spiegazioni. Caricata una volta all'avvio in [load] e tenuta in un
/// [ValueNotifier] cosi la UI si aggiorna subito senza rileggere i prefs.
class SettingsService {
  static const _key = 'explanation_mode_v1';
  static final ValueNotifier<ExplanationMode> mode =
      ValueNotifier(ExplanationMode.wrongOnly);

  // Selezioni di materie "ricordate" per sheet (es. 'exam', 'quick').
  static const _partesPrefix = 'partes_';
  static final Map<String, Set<int>> _partes = {};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key);
    if (raw != null && raw >= 0 && raw < ExplanationMode.values.length) {
      mode.value = ExplanationMode.values[raw];
    }
    for (final k in prefs.getKeys().where((k) => k.startsWith(_partesPrefix))) {
      _partes[k.substring(_partesPrefix.length)] = {
        for (final s in prefs.getStringList(k) ?? const <String>[])
          ?int.tryParse(s),
      };
    }
  }

  /// Materie salvate con "Ricorda selezione", null se non ricordate.
  static Set<int>? rememberedPartes(String key) => _partes[key];

  /// Salva [partes] per [key]; null cancella la selezione ricordata.
  static Future<void> rememberPartes(String key, Set<int>? partes) async {
    final prefs = await SharedPreferences.getInstance();
    if (partes == null) {
      _partes.remove(key);
      await prefs.remove('$_partesPrefix$key');
    } else {
      _partes[key] = {...partes};
      await prefs.setStringList(
          '$_partesPrefix$key', [for (final p in partes) '$p']);
    }
  }

  static Future<void> setMode(ExplanationMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, m.index);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Traccia quante volte ogni gid e' comparso in un quiz (non solo se
/// comparso), cosi' i builder possono pescare sempre dal minimo comune di
/// volte viste, garantendo copertura uniforme del database invece di un
/// semplice "visto/non visto" che degenera in pescate puramente casuali una
/// volta esaurito il primo giro. Caricato una volta all'avvio in [load] e
/// tenuto in cache in memoria: le letture successive sono sincrone.
class SeenService {
  static const _legacySeenKey = 'seen_gids_v1'; // formato precedente, solo migrazione
  static const _seenCountsKey = 'seen_counts_v2';
  static const _wrongKey = 'wrong_gids_v1';
  static const _wrongHistoryKey = 'wrong_history_v1';
  static const _wrongRetriedKey = 'wrong_retried_v1';
  static Map<int, int> _seenCount = {};
  static Set<int> _wrong = {};
  static Set<int> _wrongHistory = {}; // gid sbagliati gia' ritentati (e risposti correttamente)
  static Set<int> _wrongRetried = {}; // gid sbagliati ritentati almeno una volta (anche se ancora sbagliati)

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCounts = prefs.getString(_seenCountsKey);
    if (rawCounts != null) {
      final decoded = jsonDecode(rawCounts) as Map<String, dynamic>;
      _seenCount = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } else {
      // Migrazione one-shot dal vecchio set booleano: ogni gid gia' visto
      // parte con conteggio 1.
      final legacy = prefs.getStringList(_legacySeenKey) ?? const [];
      _seenCount = {for (final g in legacy.map(int.parse)) g: 1};
      if (_seenCount.isNotEmpty) await _persistCounts(prefs);
    }
    final rawWrong = prefs.getStringList(_wrongKey) ?? const [];
    final rawWrongHistory = prefs.getStringList(_wrongHistoryKey) ?? const [];
    final rawWrongRetried = prefs.getStringList(_wrongRetriedKey) ?? const [];
    _wrong = rawWrong.map(int.parse).toSet();
    _wrongHistory = rawWrongHistory.map(int.parse).toSet();
    _wrongRetried = rawWrongRetried.map(int.parse).toSet();
  }

  static Future<void> _persistCounts(SharedPreferences prefs) async {
    await prefs.setString(
        _seenCountsKey, jsonEncode(_seenCount.map((k, v) => MapEntry(k.toString(), v))));
  }

  static int countOf(int gid) => _seenCount[gid] ?? 0;

  static bool hasSeen(int gid) => countOf(gid) > 0;

  /// Numero di gid distinti visti almeno una volta (per la card "Copertura database").
  static int get seenCount => _seenCount.length;

  /// Incrementa il conteggio di ogni gid passato. Va chiamato subito dopo
  /// ogni risposta, non solo a fine quiz: altrimenti una sessione
  /// interrotta a meta' non fa avanzare la copertura per nessuna domanda.
  static Future<void> markSeen(Iterable<int> gids) async {
    for (final g in gids) {
      _seenCount[g] = (_seenCount[g] ?? 0) + 1;
    }
    final prefs = await SharedPreferences.getInstance();
    await _persistCounts(prefs);
  }

  static bool hasWrong(int gid) => _wrong.contains(gid);

  static int get wrongCount => _wrong.length;

  static Future<void> markWrong(int gid) async {
    _wrong.add(gid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_wrongKey, _wrong.map((e) => e.toString()).toList());
  }

  /// Sposta un gid da wrong a wrongHistory (l'utente l'ha ritentata e risposto corretta).
  static Future<void> markWrongSeen(int gid) async {
    _wrong.remove(gid);
    _wrongHistory.add(gid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_wrongKey, _wrong.map((e) => e.toString()).toList());
    await prefs.setStringList(_wrongHistoryKey, _wrongHistory.map((e) => e.toString()).toList());
  }

  /// Marca un gid sbagliato come ritentato (indipendentemente dall'esito):
  /// se ancora sbagliato resta in [_wrong] ma esce dal conteggio "mai rifatte".
  static Future<void> markRetried(int gid) async {
    _wrongRetried.add(gid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_wrongRetriedKey, _wrongRetried.map((e) => e.toString()).toList());
  }

  static bool hasBeenRetried(int gid) => _wrongRetried.contains(gid);

  static int get wrongNeverRetriedCount => _wrong.difference(_wrongRetried).length;

  static Future<void> clearAll() async {
    _seenCount = {};
    _wrong = {};
    _wrongHistory = {};
    _wrongRetried = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacySeenKey);
    await prefs.remove(_seenCountsKey);
    await prefs.remove(_wrongKey);
    await prefs.remove(_wrongHistoryKey);
    await prefs.remove(_wrongRetriedKey);
  }
}

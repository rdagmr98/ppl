import 'package:shared_preferences/shared_preferences.dart';

/// Traccia i gid delle domande gia' comparse in un quiz completato, cosi'
/// i builder possono proporre prima le domande mai viste. Caricato una volta
/// all'avvio in [load] e tenuto in cache in memoria: le letture successive
/// sono sincrone e sempre aggiornate anche dopo [markSeen].
class SeenService {
  static const _seenKey = 'seen_gids_v1';
  static const _wrongKey = 'wrong_gids_v1';
  static const _wrongHistoryKey = 'wrong_history_v1';
  static Set<int> _seen = {};
  static Set<int> _wrong = {};
  static Set<int> _wrongHistory = {}; // gid sbagliati gia' ritentati (e risposti correttamente)

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSeen = prefs.getStringList(_seenKey) ?? const [];
    final rawWrong = prefs.getStringList(_wrongKey) ?? const [];
    final rawWrongHistory = prefs.getStringList(_wrongHistoryKey) ?? const [];
    _seen = rawSeen.map(int.parse).toSet();
    _wrong = rawWrong.map(int.parse).toSet();
    _wrongHistory = rawWrongHistory.map(int.parse).toSet();
  }

  static bool hasSeen(int gid) => _seen.contains(gid);

  static int get seenCount => _seen.length;

  static Future<void> markSeen(Iterable<int> gids) async {
    _seen.addAll(gids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenKey, _seen.map((e) => e.toString()).toList());
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

  static int get wrongNeverRetriedCount => _wrong.difference(_seen).length;

  static Future<void> clearAll() async {
    _seen = {};
    _wrong = {};
    _wrongHistory = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
    await prefs.remove(_wrongKey);
    await prefs.remove(_wrongHistoryKey);
  }
}

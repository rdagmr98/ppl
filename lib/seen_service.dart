import 'package:shared_preferences/shared_preferences.dart';

/// Traccia i gid delle domande gia' comparse in un quiz completato, cosi'
/// i builder possono proporre prima le domande mai viste. Caricato una volta
/// all'avvio in [load] e tenuto in cache in memoria: le letture successive
/// sono sincrone e sempre aggiornate anche dopo [markSeen].
class SeenService {
  static const _key = 'seen_gids_v1';
  static Set<int> _seen = {};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    _seen = raw.map(int.parse).toSet();
  }

  static bool hasSeen(int gid) => _seen.contains(gid);

  static int get seenCount => _seen.length;

  static Future<void> markSeen(Iterable<int> gids) async {
    _seen.addAll(gids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _seen.map((e) => e.toString()).toList());
  }

  static Future<void> clearAll() async {
    _seen = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

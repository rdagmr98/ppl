import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'builder.dart';

/// Esito di un intero tentativo di quiz/esame, salvato per le statistiche.
class QuizAttempt {
  final DateTime timestamp;
  final String title;
  final bool isExam;
  final int totalQuestions;
  final int correctCount;
  final Map<int, Map<String, int>> perSubject; // parte -> {correct, total}

  QuizAttempt({
    required this.timestamp,
    required this.title,
    required this.isExam,
    required this.totalQuestions,
    required this.correctCount,
    required this.perSubject,
  });

  double get pct => totalQuestions == 0 ? 0 : correctCount / totalQuestions;

  factory QuizAttempt.fromAnswers(
      List<AnsweredQuestion> answers, String title, bool isExam) {
    final perSubject = <int, Map<String, int>>{};
    var correct = 0;
    for (final a in answers) {
      final parte = a.question.parte;
      final entry =
          perSubject.putIfAbsent(parte, () => {'correct': 0, 'total': 0});
      entry['total'] = entry['total']! + 1;
      if (a.isCorrect) {
        entry['correct'] = entry['correct']! + 1;
        correct++;
      }
    }
    return QuizAttempt(
      timestamp: DateTime.now(),
      title: title,
      isExam: isExam,
      totalQuestions: answers.length,
      correctCount: correct,
      perSubject: perSubject,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'isExam': isExam,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'perSubject': perSubject
            .map((k, v) => MapEntry(k.toString(), {'c': v['correct'], 't': v['total']})),
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) {
    final rawSubj = (j['perSubject'] as Map).cast<String, dynamic>();
    return QuizAttempt(
      timestamp: DateTime.parse(j['timestamp'] as String),
      title: j['title'] as String,
      isExam: j['isExam'] as bool,
      totalQuestions: j['totalQuestions'] as int,
      correctCount: j['correctCount'] as int,
      perSubject: rawSubj.map((k, v) {
        final m = (v as Map).cast<String, dynamic>();
        return MapEntry(int.parse(k), {
          'correct': m['c'] as int,
          'total': m['t'] as int,
        });
      }),
    );
  }
}

/// Persistenza locale (shared_preferences, funziona su web e mobile) dello
/// storico dei tentativi, usata dalla schermata Statistiche.
class StatsService {
  static const _key = 'quiz_attempts_v1';
  static const _maxStored = 300;

  static Future<void> record(QuizAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    list.add(attempt);
    if (list.length > _maxStored) {
      list.removeRange(0, list.length - _maxStored);
    }
    final raw = jsonEncode(list.map((a) => a.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<List<QuizAttempt>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => QuizAttempt.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

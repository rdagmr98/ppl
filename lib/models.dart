import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Una singola domanda del quiz.
class Question {
  final int gid; // id globale nel pool ufficiale
  final int n; // numero progressivo dentro la materia
  final String q;
  final List<String> options;
  final int correct; // indice 0-based della risposta corretta
  final int parte; // materia di appartenenza

  const Question({
    required this.gid,
    required this.n,
    required this.q,
    required this.options,
    required this.correct,
    required this.parte,
  });

  factory Question.fromJson(Map<String, dynamic> j, int parte) => Question(
        gid: (j['gid'] as num).toInt(),
        n: (j['n'] as num).toInt(),
        q: j['q'] as String,
        options: (j['options'] as List).map((e) => e.toString()).toList(),
        correct: (j['correct'] as num).toInt(),
        parte: parte,
      );
}

/// Una materia (PARTE) con le sue domande.
class Subject {
  final int parte;
  final String name;
  final List<Question> questions;

  const Subject({
    required this.parte,
    required this.name,
    required this.questions,
  });

  factory Subject.fromJson(Map<String, dynamic> j) {
    final parte = (j['parte'] as num).toInt();
    final qs = (j['questions'] as List)
        .map((e) => Question.fromJson(e as Map<String, dynamic>, parte))
        .toList();
    return Subject(parte: parte, name: j['name'] as String, questions: qs);
  }
}

/// L'intero database del quiz, caricato una sola volta dall'asset JSON.
class QuizDb {
  final String source;
  final String generated;
  final List<Subject> subjects;

  const QuizDb({
    required this.source,
    required this.generated,
    required this.subjects,
  });

  int get total =>
      subjects.fold(0, (sum, s) => sum + s.questions.length);

  Subject? byParte(int parte) {
    for (final s in subjects) {
      if (s.parte == parte) return s;
    }
    return null;
  }

  static Future<QuizDb> load() async {
    final raw = await rootBundle.loadString('assets/ppl_quiz.json');
    final j = json.decode(raw) as Map<String, dynamic>;
    final subs = (j['subjects'] as List)
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.parte.compareTo(b.parte));
    return QuizDb(
      source: (j['source'] ?? '') as String,
      generated: (j['generated'] ?? '') as String,
      subjects: subs,
    );
  }
}

/// Distribuzione ufficiale ENAC/EASA dell'esame teorico PPL(A).
/// PARTE -> numero di quesiti. Totale = 132 (le 9 materie d'esame).
const Map<int, int> examDistribution = {
  1: 20, // Regolamentazione
  2: 12, // Nozioni generali aeromobili
  3: 12, // Prestazioni di volo e pianificazione
  4: 12, // Prestazioni e limitazioni umane
  5: 20, // Meteorologia
  6: 20, // Navigazione
  7: 12, // Procedure operative
  8: 12, // Principi del volo
  9: 12, // Comunicazioni (italiano)
};

/// Quesiti aggiuntivi di fonia inglese (PARTE 10), esame separato.
const int englishExamCount = 20;

/// Soglia di superamento per materia (75%).
const double passThreshold = 0.75;

/// Nomi delle materie per numero di PARTE.
const Map<int, String> subjectNames = {
  1: 'Regolamentazione Aeronautica',
  2: 'Nozioni generali sugli Aeromobili',
  3: 'Prestazioni di volo e pianificazione',
  4: 'Prestazioni e limitazioni umane',
  5: 'Meteorologia',
  6: 'Navigazione',
  7: 'Procedure operative',
  8: 'Principi del volo',
  9: 'Comunicazioni (italiano)',
  10: 'Comunicazioni in inglese',
};

import 'dart:math';
import 'models.dart';

/// Costruisce la lista di domande per una prova d'esame realistica,
/// pescando da ogni materia il numero ufficiale di quesiti (in ordine di materia).
List<Question> buildExam(QuizDb db, {bool withEnglish = false}) {
  final rnd = Random();
  final result = <Question>[];
  final dist = Map<int, int>.from(examDistribution);
  if (withEnglish) dist[10] = englishExamCount;

  final partes = dist.keys.toList()..sort();
  for (final parte in partes) {
    final subject = db.byParte(parte);
    if (subject == null || subject.questions.isEmpty) continue;
    final pool = List<Question>.from(subject.questions)..shuffle(rnd);
    final take = min(dist[parte]!, pool.length);
    result.addAll(pool.take(take));
  }
  return result;
}

/// Costruisce una sessione di studio su una singola materia.
List<Question> buildStudy(Subject subject, {int? limit}) {
  final rnd = Random();
  final pool = List<Question>.from(subject.questions)..shuffle(rnd);
  if (limit != null && limit < pool.length) {
    return pool.take(limit).toList();
  }
  return pool;
}

/// Allenamento misto: N domande casuali da tutte le materie.
List<Question> buildMixed(QuizDb db, int count) {
  final rnd = Random();
  final all = <Question>[];
  for (final s in db.subjects) {
    all.addAll(s.questions);
  }
  all.shuffle(rnd);
  return all.take(min(count, all.length)).toList();
}

/// Esito di una domanda risposta.
class AnsweredQuestion {
  final Question question;
  final int selected; // indice scelto dall'utente
  const AnsweredQuestion(this.question, this.selected);
  bool get isCorrect => selected == question.correct;
}

import 'dart:math';
import 'models.dart';
import 'seen_service.dart';

/// Raggruppa [pool] per quante volte ogni domanda e' gia' comparsa e
/// concatena i gruppi in ordine crescente (shuffle interno ad ognuno), cosi'
/// le domande viste meno volte escono sempre prima: mai una ripetuta 4 volte
/// mentre un'altra resta a zero, a differenza di un semplice visto/non-visto
/// che degenera in pescate casuali una volta esaurito il primo giro.
List<Question> _prioritizeUnseen(List<Question> pool, Random rnd) {
  final buckets = <int, List<Question>>{};
  for (final q in pool) {
    buckets.putIfAbsent(SeenService.countOf(q.gid), () => []).add(q);
  }
  final counts = buckets.keys.toList()..sort();
  final result = <Question>[];
  for (final c in counts) {
    final bucket = buckets[c]!..shuffle(rnd);
    result.addAll(bucket);
  }
  return result;
}

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
    final pool = _prioritizeUnseen(subject.questions, rnd);
    final take = min(dist[parte]!, pool.length);
    result.addAll(pool.take(take));
  }
  return result;
}

/// Costruisce una sessione di studio su una singola materia.
List<Question> buildStudy(Subject subject, {int? limit}) {
  final rnd = Random();
  final pool = _prioritizeUnseen(subject.questions, rnd);
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
  final pool = _prioritizeUnseen(all, rnd);
  return pool.take(min(count, pool.length)).toList();
}

/// Ripassa solo le domande gia' sbagliate in quiz precedenti.
List<Question> buildErrors(QuizDb db) {
  final result = <Question>[];
  for (final s in db.subjects) {
    for (final q in s.questions) {
      if (SeenService.hasWrong(q.gid)) result.add(q);
    }
  }
  result.shuffle(Random());
  return result;
}

/// Domande sbagliate E mai rifatte (non ancora in seen).
List<Question> buildErrorsUnseen(QuizDb db, {int? limit}) {
  final result = <Question>[];
  for (final s in db.subjects) {
    for (final q in s.questions) {
      if (SeenService.hasWrong(q.gid) && !SeenService.hasBeenRetried(q.gid)) {
        result.add(q);
      }
    }
  }
  result.shuffle(Random());
  if (limit != null && limit < result.length) return result.take(limit).toList();
  return result;
}

/// Domande sbagliate di una singola materia.
List<Question> buildErrorsBySubject(Subject s, {int? limit}) {
  final result = <Question>[];
  for (final q in s.questions) {
    if (SeenService.hasWrong(q.gid)) result.add(q);
  }
  result.shuffle(Random());
  if (limit != null && limit < result.length) return result.take(limit).toList();
  return result;
}

/// Esito di una domanda risposta.
class AnsweredQuestion {
  final Question question;
  final int selected; // indice scelto dall'utente
  const AnsweredQuestion(this.question, this.selected);
  bool get isCorrect => selected == question.correct;
}

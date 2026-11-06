import 'package:flutter_test/flutter_test.dart';
import 'package:ppl_quiz/stats_service.dart';

QuizAttempt _a(Map<int, Map<String, int>> perSubject) => QuizAttempt(
      timestamp: DateTime(2026),
      title: 't',
      isExam: true,
      totalQuestions: 0,
      correctCount: 0,
      perSubject: perSubject,
    );

void main() {
  test('esame superato solo con almeno il 75% in ogni materia', () {
    expect(
        _a({
          1: {'correct': 9, 'total': 12},
          5: {'correct': 16, 'total': 16},
        }).passed,
        isTrue);
    expect(
        _a({
          1: {'correct': 12, 'total': 12},
          5: {'correct': 11, 'total': 16},
        }).passed,
        isFalse);
    expect(_a({}).passed, isFalse);
  });
}

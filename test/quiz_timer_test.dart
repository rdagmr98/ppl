// Timer d'esame: allo scadere la prova si chiude e le non risposte contano
// sbagliate. Allenamento rapido: la 99 Calcoli non duplica domande.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppl_quiz/builder.dart';
import 'package:ppl_quiz/models.dart';
import 'package:ppl_quiz/quiz_screen.dart';
import 'package:ppl_quiz/results_screen.dart';
import 'package:ppl_quiz/stats_service.dart';

Question _q(int gid, {int parte = 6, bool calc = false}) => Question(
    gid: gid,
    n: gid,
    q: 'Domanda $gid',
    options: ['giusta $gid', 'sbagliata $gid'],
    correct: 0,
    parte: parte,
    calc: calc);

void main() {
  testWidgets('tempo scaduto chiude la prova', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads',
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
    tester.view.physicalSize = const Size(360 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: QuizScreen(
        questions: [_q(1), _q(2), _q(3)],
        title: 'Esame',
        isExam: true,
        timeLimit: const Duration(seconds: 3),
      ),
    ));
    expect(find.text('00:03'), findsOneWidget);

    await tester.tap(find.text('giusta 1'));
    await tester.pump(const Duration(milliseconds: 600)); // avanza da sola
    expect(find.text('Domanda 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(ResultsScreen), findsOneWidget);

    final a = (await StatsService.loadAll()).single;
    expect(a.totalQuestions, 3);
    expect(a.correctCount, 1);
  });

  test('buildMixed: Calcoli senza doppioni', () {
    final calc = _q(10, calc: true);
    final db = QuizDb(source: '', generated: '', subjects: [
      Subject(parte: 6, name: 'Navigazione', questions: [calc, _q(11)]),
      Subject(parte: 99, name: 'Calcoli', questions: [calc]),
    ]);
    expect(buildMixed(db, 30, {6, 99}).length, 2);
    expect(buildMixed(db, 30, {99}).single.gid, 10);
  });
}

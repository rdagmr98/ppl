// Smoke test: ogni scheda del bignami si apre, ogni argomento si espande
// senza overflow/eccezioni e i calcolatori danno un risultato.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppl_quiz/bignami_screen.dart';
import 'package:ppl_quiz/models.dart';

void main() {
  testWidgets('bignami: tab, argomenti e calcolatori', (tester) async {
    // AdMob senza plugin nativo: ogni chiamata risponde "ok" e l'annuncio
    // resta non caricato (SizedBox.shrink).
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads',
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
    // larghezza telefono, altezza enorme: tutta la lista costruita, niente scroll
    tester.view.physicalSize = const Size(360 * 3, 8000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final db = QuizDb(source: '', generated: '', subjects: [
      for (var p = 1; p <= 10; p++)
        Subject(parte: p, name: subjectNames[p]!, questions: const []),
    ]);
    // da Statistiche: si apre sulla scheda della materia (P10 -> Comunicazioni)
    await tester.pumpWidget(MaterialApp(home: BignamiScreen(db: db, initialParte: 10)));
    expect(DefaultTabController.of(tester.element(find.byType(TabBarView))).index, 8);

    await tester.pumpWidget(MaterialApp(home: BignamiScreen(db: db)));
    final tabs = DefaultTabController.of(tester.element(find.byType(TabBarView)));

    for (var i = 0; i < tabs.length; i++) {
      tabs.index = i;
      await tester.pumpAndSettle();
      final n = find.byType(ExpansionTile).evaluate().length;
      expect(n, greaterThan(0));
      for (var j = 0; j < n; j++) {
        await tester.tap(find.byType(ExpansionTile).at(j));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: 'tab $i');
      if (i == 5) {
        // Navigazione → 1 in 60: 3 NM su 30 NM = 6°
        expect(find.text('Errore angolare 6°'), findsOneWidget);
      }
    }
  });
}

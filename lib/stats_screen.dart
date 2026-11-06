import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'seen_service.dart';
import 'stats_service.dart';
import 'ads_service.dart';
import 'bignami_screen.dart';
import 'main.dart' show showErrorPicker;

class _SubjectAgg {
  final int parte;
  int correct = 0;
  int total = 0;
  _SubjectAgg(this.parte);
  double get pct => total == 0 ? 0 : correct / total;
  bool get passed => pct >= passThreshold;
}

enum _Readiness { ready, close, notReady }

class StatsScreen extends StatefulWidget {
  final QuizDb db;
  const StatsScreen({super.key, required this.db});
  int get totalDbQuestions => db.total;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _passColor = Color(0xFF69F0AE);
  static const _failColor = Color(0xFFFF5252);
  static const _readyBg = Color(0xFF2E7D32);
  static const _closeBg = Color(0xFF8D6E00);
  static const _closeAccent = Color(0xFFFFD54F);
  static const _notReadyBg = Color(0xFFB71C1C);
  static const _trendColor = Color(0xFF1E88E5);

  late Future<List<QuizAttempt>> _future;

  // Ricarica a ogni ritorno su questa schermata (es. dopo un ripasso errori
  // avviato da qui): isCurrentOf crea la dipendenza sul cambio di route.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) ?? true) {
      _future = StatsService.loadAll();
    }
  }

  void _reload() {
    setState(() {
      _future = StatsService.loadAll();
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancellare lo storico?'),
        content: const Text(
            'Tutte le statistiche salvate finora andranno perse. '
            'L\'azione non è reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StatsService.clearAll();
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Statistiche'),
        actions: [
          FutureBuilder<List<QuizAttempt>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Cancella storico',
                onPressed: _confirmClear,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<QuizAttempt>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final attempts = snap.data!.where((a) => !a.isErrorReview).toList();
          if (attempts.isEmpty) return _emptyState(context);
          return _content(context, attempts);
        },
      ),
    ));
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.query_stats,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Nessuna statistica ancora',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa almeno un quiz o un esame per vedere qui il tuo '
              'livello di preparazione.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // Finestra "recente" per il giudizio di preparazione: non un tempo fisso,
  // ma un numero di tentativi (dal piu' recente indietro) che copra almeno
  // il 15% del database di domande — un campione ampio e rappresentativo
  // del syllabus, non solo le ultimissime sessioni.
  static const _recentCoverageTarget = 0.15;

  static String _date(DateTime d) => '${d.day}/${d.month}';

  static TextStyle _muted(ThemeData theme, [double size = 12]) =>
      TextStyle(fontSize: size, color: theme.colorScheme.onSurfaceVariant);

  Widget _content(BuildContext context, List<QuizAttempt> attempts) {
    final theme = Theme.of(context);

    final targetQuestions =
        (widget.totalDbQuestions * _recentCoverageTarget).round();
    final windowed = <QuizAttempt>[];
    var coveredQuestions = 0;
    for (var i = attempts.length - 1;
        i >= 0 && coveredQuestions < targetQuestions;
        i--) {
      windowed.add(attempts[i]);
      coveredQuestions += attempts[i].totalQuestions;
    }
    final usedFullHistory = windowed.length == attempts.length;
    final coveragePct = widget.totalDbQuestions == 0
        ? 0
        : (coveredQuestions / widget.totalDbQuestions * 100).round();

    final Map<int, _SubjectAgg> byParte = {};
    var totalCorrect = 0;
    var totalQuestions = 0;
    for (final a in windowed) {
      totalCorrect += a.correctCount;
      totalQuestions += a.totalQuestions;
      for (final entry in a.perSubject.entries) {
        final agg =
            byParte.putIfAbsent(entry.key, () => _SubjectAgg(entry.key));
        agg.correct += entry.value['correct']!;
        agg.total += entry.value['total']!;
      }
    }
    final subs = byParte.values.toList();
    // Elenco materie: tutte e 9 d'esame (fonia EN solo se allenata), anche
    // quelle uscite dalla finestra recente, che restano in grigio.
    final partes = {for (var p = 1; p <= 9; p++) p, ...byParte.keys}.toList()
      ..sort();
    final recentAttempts =
        attempts.length > 10 ? attempts.sublist(attempts.length - 10) : attempts;
    final totalCorrectAll = attempts.fold<int>(0, (sum, a) => sum + a.correctCount);
    final totalQuestionsAll = attempts.fold<int>(0, (sum, a) => sum + a.totalQuestions);
    final overallPct = totalQuestions == 0 ? 0.0 : totalCorrect / totalQuestions;
    final allPassed = subs.isNotEmpty && subs.every((s) => s.passed);

    final _Readiness readiness;
    if (allPassed && overallPct >= passThreshold) {
      readiness = _Readiness.ready;
    } else if (overallPct >= passThreshold - 0.10) {
      readiness = _Readiness.close;
    } else {
      readiness = _Readiness.notReady;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _readinessCard(theme, readiness, overallPct, totalCorrect,
            totalQuestions, windowed.length, usedFullHistory, coveragePct),
        const SizedBox(height: 12),
        _examsCard(theme, attempts.where((a) => a.isExam).toList()),
        const SizedBox(height: 12),
        _errorsCard(theme),
        const SizedBox(height: 12),
        _dbCoverageCard(theme),
        const SizedBox(height: 28),
        Text('Andamento per materia',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '${usedFullHistory ? 'Su tutti i tentativi disponibili' : 'Negli ultimi ${windowed.length} tentativi (~$coveragePct% del database)'}'
          ' · tocca una materia per il bignami',
          style: _muted(theme),
        ),
        const SizedBox(height: 12),
        for (final p in partes) _subjectRow(context, p, byParte[p]),
        if (attempts.length > 1) ...[
          const SizedBox(height: 28),
          Text('Andamento nel tempo',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Corrette negli ultimi ${recentAttempts.length} tentativi · '
            'punti bianchi = esami',
            style: _muted(theme),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _trendChart(theme, recentAttempts)),
        ],
        const SizedBox(height: 20),
        Center(
          child: Text(
            '${attempts.length} tentativi · $totalQuestionsAll risposte · '
            '${(totalCorrectAll / totalQuestionsAll * 100).round()}% corrette',
            style: _muted(theme),
          ),
        ),
        const SizedBox(height: 24),
        const PplNativeAd(adUnitId: AdIds.nativeFooter),
        const SizedBox(height: 8),
        const Center(child: PplBannerAd()),
      ],
    );
  }

  Widget _readinessCard(
      ThemeData theme,
      _Readiness r,
      double overallPct,
      int correct,
      int total,
      int attemptsCount,
      bool usedFullHistory,
      int coveragePct) {
    final Color bg;
    final IconData icon;
    final String title;
    final String subtitle;
    switch (r) {
      case _Readiness.ready:
        bg = _readyBg;
        icon = Icons.verified;
        title = 'PRONTO PER L\'ESAME';
        subtitle = 'Hai superato il 75% in tutte le materie allenate.';
        break;
      case _Readiness.close:
        bg = _closeBg;
        icon = Icons.trending_up;
        title = 'QUASI PRONTO';
        subtitle = 'Sei vicino alla soglia: ripassa le materie sotto il 75%.';
        break;
      case _Readiness.notReady:
        bg = _notReadyBg;
        icon = Icons.school;
        title = 'DA MIGLIORARE';
        subtitle = 'Servono altri ripassi prima di affrontare l\'esame.';
        break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('${(overallPct * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                tooltip: 'Dettagli',
                onPressed: () => _showReadinessInfo(
                    correct, total, subtitle, usedFullHistory, attemptsCount, coveragePct),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReadinessInfo(int correct, int total, String subtitle,
      bool usedFullHistory, int attemptsCount, int coveragePct) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dettagli prontezza'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$correct / $total risposte corrette'),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 8),
            Text(usedFullHistory
                ? 'Basato su $attemptsCount tentativi completati.'
                : 'Basato su $attemptsCount tentativi recenti '
                    '(~$coveragePct% del database).'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  /// Card compatta comune a esami, errori e copertura.
  Widget _infoCard(ThemeData theme,
      {required IconData icon,
      required Color color,
      required String title,
      required List<Widget> body,
      Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...body,
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 14), trailing],
        ],
      ),
    );
  }

  Widget _bar(ThemeData theme, double value, Color color,
      {double height = 8, Color? bg}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        color: color,
        backgroundColor: bg ?? theme.colorScheme.surfaceContainerLow,
      ),
    );
  }

  Widget _examsCard(ThemeData theme, List<QuizAttempt> exams) {
    final last = exams.isEmpty ? null : exams.last;
    final recent = exams.length > 10 ? exams.sublist(exams.length - 10) : exams;
    final passed = exams.where((e) => e.passed).length;
    return _infoCard(
      theme,
      icon: Icons.flight_takeoff,
      color: _trendColor,
      title: 'Esami simulati',
      body: [
        if (last == null)
          Text('Nessuno ancora: prova un esame completo o per materie',
              style: _muted(theme))
        else ...[
          Row(
            children: [
              for (final e in recent)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                      color: e.passed ? _passColor : _failColor,
                      shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Superati $passed su ${exams.length} · ultimo '
            '${(last.pct * 100).round()}% del ${_date(last.timestamp)}',
            style: _muted(theme),
          ),
        ],
      ],
    );
  }

  Widget _errorsCard(ThemeData theme) {
    final open = SeenService.wrongCount;
    final recovered = SeenService.recoveredCount;
    final total = open + recovered;
    return _infoCard(
      theme,
      icon: Icons.error_outline,
      color: const Color(0xFFD32F2F),
      title: 'Errori',
      body: [
        if (total > 0) ...[
          _bar(theme, recovered / total, _passColor),
          const SizedBox(height: 4),
        ],
        Text(
          total == 0
              ? 'Nessun errore finora'
              : '$open da ripassare · $recovered recuperati',
          style: _muted(theme),
        ),
      ],
      trailing: FilledButton.tonal(
        onPressed: open == 0 ? null : () => showErrorPicker(context, widget.db),
        child: const Text('Ripassa'),
      ),
    );
  }

  Widget _dbCoverageCard(ThemeData theme) {
    final seen = SeenService.seenCount;
    final total = widget.totalDbQuestions;
    final pct = total == 0 ? 0.0 : (seen / total).clamp(0.0, 1.0);
    final remaining = (total - seen).clamp(0, total);
    return _infoCard(
      theme,
      icon: Icons.library_books_outlined,
      color: theme.colorScheme.primary,
      title: 'Copertura database',
      body: [
        _bar(theme, pct, theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          remaining > 0
              ? '$seen / $total domande viste ($remaining da fare)'
              : '$seen / $total domande viste (completato!)',
          style: _muted(theme),
        ),
      ],
      trailing: Text('${(pct * 100).round()}%',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary)),
    );
  }

  Widget _subjectRow(BuildContext context, int parte, _SubjectAgg? s) {
    final theme = Theme.of(context);
    final name = subjectNames[parte] ?? 'Materia $parte';
    final pct = s == null || s.total == 0 ? null : s.pct;
    final passed = pct != null && pct >= passThreshold;
    final col = pct == null
        ? theme.colorScheme.onSurfaceVariant
        : passed
            ? _passColor
            : _failColor;
    final qs = widget.db.byParte(parte)?.questions ?? const <Question>[];
    final seen = qs.where((q) => SeenService.hasSeen(q.gid)).length;
    // tocca la materia per ripassarla sul bignami
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BignamiScreen(db: widget.db, initialParte: parte))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
                pct == null
                    ? Icons.remove_circle_outline
                    : passed
                        ? Icons.check_circle
                        : Icons.cancel,
                color: col,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  _bar(theme, pct ?? 0, col,
                      height: 6, bg: theme.colorScheme.surfaceContainerHighest),
                  const SizedBox(height: 3),
                  Text(
                      pct == null
                          ? 'Non allenata di recente · viste $seen/${qs.length}'
                          : 'Viste $seen/${qs.length} domande',
                      style: _muted(theme, 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(pct == null ? '–' : '${s!.correct}/${s.total}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              child: Text(pct == null ? '' : '${(pct * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: col, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.menu_book,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _trendChart(ThemeData theme, List<QuizAttempt> attempts) {
    final n = attempts.length;
    final spots = [
      for (int i = 0; i < n; i++) FlSpot(i.toDouble(), attempts[i].pct * 100),
    ];
    final labelInterval = (n / 6).ceil().clamp(1, n).toDouble();
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            maxContentWidth: 180,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${spot.y.round()}%\n',
                  TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${attempts[spot.spotIndex].title}\n'
                          '${_date(attempts[spot.spotIndex].timestamp)}',
                      style: TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.normal,
                          fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text('${value.toInt()}', style: _muted(theme, 10)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: labelInterval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text('${value.toInt() + 1}', style: _muted(theme, 10)),
              ),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: passThreshold * 100,
            color: _closeAccent,
            strokeWidth: 2,
            dashArray: const [8, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: const TextStyle(
                  color: _closeAccent, fontSize: 10, fontWeight: FontWeight.bold),
              labelResolver: (line) => '75%',
            ),
          ),
        ]),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            preventCurveOverShooting: true,
            color: _trendColor,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, i) => attempts[i].isExam
                  ? FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: _trendColor)
                  : FlDotCirclePainter(
                      radius: 3, color: _trendColor, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(show: true, color: _trendColor.withValues(alpha: 0.15)),
            spots: spots,
          ),
        ],
      ),
    );
  }
}

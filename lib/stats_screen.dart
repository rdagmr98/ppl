import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'seen_service.dart';
import 'stats_service.dart';

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

  @override
  void initState() {
    super.initState();
    _future = StatsService.loadAll();
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
    final subs = byParte.values.toList()
      ..sort((a, b) => a.parte.compareTo(b.parte));
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
        const SizedBox(height: 16),
        _dbCoverageCard(theme),
        const SizedBox(height: 28),
        Text('Andamento per materia',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          usedFullHistory
              ? 'Prontezza per materia su tutti i tentativi disponibili'
              : 'Prontezza per materia negli ultimi ${windowed.length} '
                  'tentativi (~$coveragePct% del database)',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: _subjectBarChart(theme, subs)),
        const SizedBox(height: 16),
        for (final s in subs) _subjectRow(context, s),
        const SizedBox(height: 28),
        if (attempts.length > 1) ...[
          Text('Andamento nel tempo',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Percentuale corrette negli ultimi ${recentAttempts.length} tentativi, in ordine cronologico',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _trendChart(theme, recentAttempts)),
          const SizedBox(height: 28),
        ],
        Text('Totale risposte',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(height: 160, child: _overallSection(theme, totalCorrectAll, totalQuestionsAll)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '${attempts.length} tentativi completati',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
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

  void _showDbCoverageInfo() {
    final rows = widget.db.subjects.map((s) {
      final seen = s.questions.where((q) => SeenService.hasSeen(q.gid)).length;
      return (name: s.name, seen: seen, total: s.questions.length);
    }).toList();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copertura per materia'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: rows.map((r) {
                final pct = r.total == 0 ? 0 : (r.seen / r.total * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(r.name)),
                      Text('${r.seen}/${r.total} ($pct%)'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
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

  Widget _dbCoverageCard(ThemeData theme) {
    final seen = SeenService.seenCount;
    final total = widget.totalDbQuestions;
    final pct = total == 0 ? 0.0 : (seen / total).clamp(0.0, 1.0);
    final remaining = (total - seen).clamp(0, total);
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
          Icon(Icons.library_books_outlined,
              size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Copertura database',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining > 0
                      ? '$seen / $total domande ($remaining da fare)'
                      : '$seen / $total domande (completato!)',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text('${(pct * 100).round()}%',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary)),
          IconButton(
            icon: Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant, size: 20),
            tooltip: 'Dettagli per materia',
            onPressed: _showDbCoverageInfo,
          ),
        ],
      ),
    );
  }

  Widget _subjectBarChart(ThemeData theme, List<_SubjectAgg> subs) {
    if (subs.isEmpty) return const SizedBox.shrink();
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final s = subs[group.x.toInt()];
              return BarTooltipItem(
                '${subjectNames[s.parte] ?? 'Materia ${s.parte}'}\n',
                TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
                children: [
                  TextSpan(
                    text: '${s.correct}/${s.total} (${(s.pct * 100).round()}%)',
                    style: TextStyle(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.normal,
                        fontSize: 12),
                  ),
                ],
              );
            },
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
                child: Text('${value.toInt()}',
                    style:
                        TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= subs.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text('P${subs[i].parte}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                );
              },
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
        barGroups: [
          for (int i = 0; i < subs.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: subs[i].pct * 100,
                  color: subs[i].passed ? _passColor : _failColor,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _subjectRow(BuildContext context, _SubjectAgg s) {
    final theme = Theme.of(context);
    final name = subjectNames[s.parte] ?? 'Materia ${s.parte}';
    final col = s.passed ? _passColor : _failColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(s.passed ? Icons.check_circle : Icons.cancel, color: col, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.pct,
                    minHeight: 6,
                    color: col,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${s.correct}/${s.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text('${(s.pct * 100).round()}%',
                textAlign: TextAlign.end,
                style: TextStyle(color: col, fontWeight: FontWeight.bold)),
          ),
        ],
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
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${spot.y.round()}%',
                  TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold),
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
                child: Text('${value.toInt()}',
                    style:
                        TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
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
                child: Text('${value.toInt() + 1}',
                    style:
                        TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
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
            color: _trendColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: _trendColor.withValues(alpha: 0.15)),
            spots: spots,
          ),
        ],
      ),
    );
  }

  Widget _overallSection(ThemeData theme, int correct, int total) {
    final wrong = total - correct;
    if (total == 0) return const SizedBox.shrink();
    final pct = correct / total;
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 46,
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                  sections: [
                    PieChartSectionData(
                      value: correct.toDouble(),
                      color: _passColor,
                      title: '',
                      radius: 24,
                    ),
                    if (wrong > 0)
                      PieChartSectionData(
                        value: wrong.toDouble(),
                        color: _failColor,
                        title: '',
                        radius: 24,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(pct * 100).round()}%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('corrette',
                      style:
                          TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendRow(_passColor, 'Corrette', correct),
              const SizedBox(height: 12),
              _legendRow(_failColor, 'Errate', wrong),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

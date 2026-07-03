import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'models.dart';
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
  const StatsScreen({super.key});

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
    return Scaffold(
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
          final attempts = snap.data!;
          if (attempts.isEmpty) return _emptyState(context);
          return _content(context, attempts);
        },
      ),
    );
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

  Widget _content(BuildContext context, List<QuizAttempt> attempts) {
    final theme = Theme.of(context);

    final Map<int, _SubjectAgg> byParte = {};
    var totalCorrect = 0;
    var totalQuestions = 0;
    for (final a in attempts) {
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
        _readinessCard(
            theme, readiness, overallPct, totalCorrect, totalQuestions, attempts.length),
        const SizedBox(height: 28),
        Text('Andamento per materia',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Percentuale di risposte corrette cumulata su tutti i tentativi',
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
            'Percentuale corrette per ogni tentativo completato, in ordine cronologico',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _trendChart(theme, attempts)),
          const SizedBox(height: 28),
        ],
        Text('Totale risposte',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(height: 160, child: _overallSection(theme, totalCorrect, totalQuestions)),
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

  Widget _readinessCard(ThemeData theme, _Readiness r, double overallPct,
      int correct, int total, int attemptsCount) {
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
          Text('${(overallPct * 100).round()}%',
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('$correct / $total risposte corrette',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text('basato su $attemptsCount tentativi completati',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
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

import 'package:flutter/material.dart';
import 'models.dart';
import 'builder.dart';

class _SubScore {
  final int parte;
  int correct = 0;
  int total = 0;
  _SubScore(this.parte);
  double get pct => total == 0 ? 0 : correct / total;
  bool get passed => pct >= passThreshold;
}

class ResultsScreen extends StatelessWidget {
  final List<AnsweredQuestion> answers;
  final String title;
  final bool isExam;
  const ResultsScreen({
    super.key,
    required this.answers,
    required this.title,
    this.isExam = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCorrect = answers.where((a) => a.isCorrect).length;
    final total = answers.length;
    final pct = total == 0 ? 0.0 : totalCorrect / total;

    // raggruppa per materia
    final Map<int, _SubScore> byParte = {};
    for (final a in answers) {
      final s = byParte.putIfAbsent(a.question.parte, () => _SubScore(a.question.parte));
      s.total++;
      if (a.isCorrect) s.correct++;
    }
    final subs = byParte.values.toList()..sort((a, b) => a.parte.compareTo(b.parte));
    final allPassed = subs.every((s) => s.passed);
    final wrong = answers.where((a) => !a.isCorrect).toList();

    final passColor = const Color(0xFF2E7D32);
    final failColor = const Color(0xFFB71C1C);
    final headColor = isExam ? (allPassed ? passColor : failColor) : theme.colorScheme.primaryContainer;

    return Scaffold(
      appBar: AppBar(title: const Text('Risultato')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: headColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (isExam)
                  Text(
                    allPassed ? 'PROMOSSO' : 'NON PROMOSSO',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: isExam ? Colors.white : null,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '$totalCorrect / $total',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isExam ? Colors.white : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${(pct * 100).round()}% corrette',
                  style: TextStyle(
                    fontSize: 16,
                    color: isExam
                        ? Colors.white70
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (isExam) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Esame superato con il 75% in ogni materia',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Dettaglio per materia',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final s in subs) _subjectRow(context, s),
          const SizedBox(height: 20),
          if (wrong.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _ReviewScreen(wrong: wrong)),
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text('Rivedi i ${wrong.length} errori'),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home),
            label: const Text('Torna alla home'),
          ),
        ],
      ),
    );
  }

  Widget _subjectRow(BuildContext context, _SubScore s) {
    final theme = Theme.of(context);
    final name = subjectNames[s.parte] ?? 'Materia ${s.parte}';
    final col = s.passed ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);
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
          Text('${s.correct}/${s.total}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
}

class _ReviewScreen extends StatelessWidget {
  final List<AnsweredQuestion> wrong;
  const _ReviewScreen({required this.wrong});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Errori (${wrong.length})')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: wrong.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (context, idx) {
          final a = wrong[idx];
          final q = a.question;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subjectNames[q.parte] ?? 'Materia ${q.parte}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(q.q,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
              const SizedBox(height: 12),
              _reviewOption(context, q.options[q.correct], true, 'Corretta'),
              if (a.selected >= 0 && a.selected < q.options.length)
                _reviewOption(
                    context, q.options[a.selected], false, 'La tua risposta'),
            ],
          );
        },
      ),
    );
  }

  Widget _reviewOption(
      BuildContext context, String text, bool correct, String label) {
    final bg = correct ? const Color(0xFF1B3A24) : const Color(0xFF3A1B1B);
    final border = correct ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel,
              color: border, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: border,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 15, height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

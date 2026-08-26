import 'package:flutter/material.dart';
import 'models.dart';
import 'ads_service.dart';
import 'quiz_screen.dart' show openFigureZoom;

/// Elenco materie per l'accesso diretto al database (sola consultazione,
/// nessuna logica quiz): domanda + tutte le opzioni + risposta corretta +
/// spiegazione, tutte visibili subito.
class DatabaseSubjectPickerScreen extends StatelessWidget {
  final QuizDb db;
  const DatabaseSubjectPickerScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Database per materia')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: db.subjects.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == db.subjects.length) {
            return const Column(
              children: [
                PplNativeAd(adUnitId: AdIds.nativeFooter),
                SizedBox(height: 8),
                Center(child: PplBannerAd()),
              ],
            );
          }
          final s = db.subjects[i];
          return Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DatabaseBrowserScreen(subject: s),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text('${s.parte}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(s.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    Text('${s.questions.length}',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Vista di sola consultazione: tutte le domande di una materia con opzioni,
/// risposta corretta evidenziata e spiegazione, senza alcuna logica di quiz.
class DatabaseBrowserScreen extends StatelessWidget {
  final Subject subject;
  const DatabaseBrowserScreen({super.key, required this.subject});

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('${subject.questions.length} domande',
                style: const TextStyle(fontSize: 12)),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: subject.questions.length,
        itemBuilder: (context, i) => _QuestionCard(q: subject.questions[i]),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question q;
  const _QuestionCard({required this.q});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${q.n}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
                const SizedBox(width: 8),
                Text('gid ${q.gid}',
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            Text(q.q, style: const TextStyle(fontSize: 15, height: 1.3)),
            if (q.fig != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => openFigureZoom(context, q.fig!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/figures/${q.fig}.webp'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            for (int j = 0; j < q.options.length; j++)
              _OptionRow(
                letter: DatabaseBrowserScreen._letters[j],
                text: q.options[j],
                correct: j == q.correct,
              ),
            if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(q.explanation!,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String letter;
  final String text;
  final bool correct;
  const _OptionRow({required this.letter, required this.text, required this.correct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final good = const Color(0xFF43A047);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: correct ? good.withValues(alpha: 0.22) : Colors.transparent,
              border: Border.all(
                  color: correct ? good : theme.colorScheme.outlineVariant,
                  width: 1.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(letter,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: correct ? good : theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: correct ? FontWeight.w600 : FontWeight.normal,
                    color: correct ? good : theme.colorScheme.onSurface)),
          ),
          if (correct) Padding(
            padding: const EdgeInsets.only(left: 4, top: 1),
            child: Icon(Icons.check_circle, size: 16, color: good),
          ),
        ],
      ),
    );
  }
}

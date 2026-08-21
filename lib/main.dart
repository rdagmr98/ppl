import 'package:flutter/material.dart';
import 'models.dart';
import 'builder.dart';
import 'quiz_screen.dart';
import 'stats_screen.dart';
import 'settings_service.dart';
import 'seen_service.dart';
import 'database_browser_screen.dart';
import 'bignami_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.load();
  await SeenService.load();
  runApp(const PplApp());
}

class PplApp extends StatelessWidget {
  const PplApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Quiz PPL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0E1116),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<QuizDb> _dbFuture;

  @override
  void initState() {
    super.initState();
    _dbFuture = QuizDb.load();
  }

  void _start(List<Question> questions, String title, {bool isExam = false}) {
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QuizScreen(questions: questions, title: title, isExam: isExam),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<QuizDb>(
        future: _dbFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Errore caricamento: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildHome(context, snap.data!);
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, QuizDb db) {
    final theme = Theme.of(context);
    final modes = [
      _ModeCard(
        icon: Icons.flight_takeoff,
        color: const Color(0xFF1E88E5),
        title: 'Esame completo',
        subtitle: '132 quesiti',
        onTap: () => _start(buildExam(db), 'Esame completo', isExam: true),
      ),
      _ModeCard(
        icon: Icons.record_voice_over,
        color: const Color(0xFF26A69A),
        title: 'Esame + fonia EN',
        subtitle: '152 quesiti',
        onTap: () => _start(
            buildExam(db, withEnglish: true), 'Esame + inglese',
            isExam: true),
      ),
      _ModeCard(
        icon: Icons.bolt,
        color: const Color(0xFFFFB300),
        title: 'Allenamento rapido',
        subtitle: '30 quesiti',
        onTap: () => _start(buildMixed(db, 30), 'Allenamento rapido'),
      ),
      _ModeCard(
        icon: Icons.menu_book,
        color: const Color(0xFF7E57C2),
        title: 'Studio per materia',
        subtitle: 'Scegli materia',
        onTap: () => _openSubjects(db),
      ),
      _ModeCard(
        icon: Icons.query_stats,
        color: const Color(0xFF00ACC1),
        title: 'Statistiche',
        subtitle: 'Sei pronto?',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StatsScreen(db: db),
          ),
        ),
      ),
      _ErrorsCard(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _ErrorPickerSheet(db: db),
        ),
      ),
      _ModeCard(
        icon: Icons.travel_explore,
        color: const Color(0xFF43A047),
        title: 'Database per materia',
        subtitle: 'Domande, risposte e spiegazioni',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DatabaseSubjectPickerScreen(db: db),
          ),
        ),
      ),
      _ModeCard(
        icon: Icons.explore,
        color: const Color(0xFFEF6C00),
        title: 'Bignami PPL(A)',
        subtitle: 'Formule e regole, offline',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BignamiScreen()),
        ),
      ),
    ];
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          backgroundColor: theme.colorScheme.surface,
          toolbarHeight: 84,
          flexibleSpace: const FlexibleSpaceBar(
            background: _HeaderArt(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Center(child: _ExplanationModeSelector()),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            delegate: SliverChildListDelegate(modes),
          ),
        ),
      ],
    );
  }

  void _openSubjects(QuizDb db) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectPickerScreen(
          db: db,
          onStart: (questions, title) {
            Navigator.of(context).pop();
            _start(questions, title);
          },
        ),
      ),
    );
  }

}


/// Card per il ripasso degli errori: apre un bottom sheet con tre opzioni.
class _ErrorsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ErrorsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ModeCard(
      icon: Icons.error_outline,
      color: const Color(0xFFD32F2F),
      title: 'Ripassa errori',
      subtitle: '${SeenService.wrongCount} domande sbagliate',
      onTap: onTap,
    );
  }
}

/// Bottom sheet con tre opzioni per il ripasso errori.
class _ErrorPickerSheet extends StatelessWidget {
  final QuizDb db;
  const _ErrorPickerSheet({required this.db});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neverRetried = SeenService.wrongNeverRetriedCount;
    final bySubject = <_SubjectEntry>[];
    for (final s in db.subjects) {
      int count = 0;
      for (final q in s.questions) {
        if (SeenService.hasWrong(q.gid)) count++;
      }
      if (count > 0) bySubject.add(_SubjectEntry(s, count));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ripasso errori',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Mai rifatte
            _buildTile(
              context, theme,
              icon: Icons.replay,
              color: const Color(0xFFFF8F00),
              title: 'Solo mai rifatte',
              subtitle: '$neverRetried domande',
              onTap: neverRetried == 0
                  ? null
                  : () => _startNeverRetried(context),
            ),
            const SizedBox(height: 12),
            // Per materie
            _buildTile(
              context, theme,
              icon: Icons.category,
              color: const Color(0xFF7E57C2),
              title: 'Per materie',
              subtitle: '${bySubject.length} materie',
              onTap: bySubject.isEmpty
                  ? null
                  : () => _showBySubject(context, bySubject),
            ),
            const SizedBox(height: 12),
            // Random
            _buildTile(
              context, theme,
              icon: Icons.shuffle,
              color: const Color(0xFFD32F2F),
              title: 'Random',
              subtitle: '${SeenService.wrongCount} domande',
              onTap: SeenService.wrongCount == 0
                  ? null
                  : () => _startRandom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, ThemeData theme,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }

  void _startNeverRetried(BuildContext context) {
    Navigator.pop(context);
    final questions = buildErrorsUnseen(db);
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
            questions: questions,
            title: 'Errori: mai rifatte',
            isErrorReview: true),
      ),
    );
  }

  void _showBySubject(BuildContext context, List<_SubjectEntry> entries) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ErrorSubjectSheet(entries: entries),
    );
  }

  void _startRandom(BuildContext context) {
    Navigator.pop(context);
    final questions = buildErrors(db);
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
            questions: questions,
            title: 'Errori: random',
            isErrorReview: true),
      ),
    );
  }
}

class _SubjectEntry {
  final Subject subject;
  final int count;
  const _SubjectEntry(this.subject, this.count);
}

/// Bottom sheet per scegliere materia nel ripasso errori.
class _ErrorSubjectSheet extends StatelessWidget {
  final List<_SubjectEntry> entries;
  const _ErrorSubjectSheet({required this.entries});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scegli materia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSubjectTile(context, e),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectTile(BuildContext context, _SubjectEntry e) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _choose(context, e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text('${e.subject.parte}',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(e.subject.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('${e.count}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }

  void _choose(BuildContext context, _SubjectEntry e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ErrorSubjectCountSheet(subject: e.subject, wrongCount: e.count),
    );
  }
}

/// Bottom sheet per scegliere il numero di domande in una materia dal ripasso errori.
class _ErrorSubjectCountSheet extends StatelessWidget {
  final Subject subject;
  final int wrongCount;
  const _ErrorSubjectCountSheet({required this.subject, required this.wrongCount});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$wrongCount domande sbagliate',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in [10, 20, 40].where((x) => x < wrongCount))
                  FilledButton.tonal(
                    onPressed: () => _start(context, c),
                    child: Text('$c domande'),
                  ),
                FilledButton(
                  onPressed: () => _start(context, null),
                  child: Text('Tutte ($wrongCount)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _start(BuildContext context, int? limit) {
    Navigator.pop(context); // count sheet
    Navigator.pop(context); // subject sheet
    final questions = buildErrorsBySubject(subject, limit: limit);
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
            questions: questions, title: 'Errori: ${subject.name}', isErrorReview: true),
      ),
    );
  }
}

/// Selettore a 3 posizioni (sesta cella della griglia home, sotto
/// _ExplanationModeCard) per decidere quando mostrare la spiegazione durante
/// il quiz: sempre, solo se sbagliata, oppure mai ("flash", avanza subito
/// anche su errore).
class _ExplanationModeSelector extends StatelessWidget {
  const _ExplanationModeSelector();

  static const _icons = {
    ExplanationMode.always: Icons.menu_book,
    ExplanationMode.wrongOnly: Icons.error_outline,
    ExplanationMode.flash: Icons.bolt,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<ExplanationMode>(
      valueListenable: SettingsService.mode,
      builder: (context, mode, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final m in ExplanationMode.values)
                      _segment(context, theme, m, mode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode.description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }

  Widget _segment(BuildContext context, ThemeData theme, ExplanationMode m,
      ExplanationMode current) {
    final selected = m == current;
    return Tooltip(
      message: m.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () => SettingsService.setMode(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Icon(_icons[m], size: 22,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _HeaderArt extends StatelessWidget {
  const _HeaderArt();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1116), Color(0xFF13294B)],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0.7, -0.5),
            child: Opacity(
              opacity: 0.55,
              child: Image.asset(
                'assets/icon/icon_foreground.png',
                width: 130,
                height: 130,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Quiz PPL(A)',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubjectPickerScreen extends StatelessWidget {
  final QuizDb db;
  final void Function(List<Question> questions, String title) onStart;
  const SubjectPickerScreen({
    super.key,
    required this.db,
    required this.onStart,
  });

  void _choose(BuildContext context, Subject s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final counts = [10, 20, 40].where((c) => c < s.questions.length).toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${s.questions.length} domande disponibili',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in counts)
                      FilledButton.tonal(
                        onPressed: () =>
                            onStart(buildStudy(s, limit: c), s.name),
                        child: Text('$c domande'),
                      ),
                    FilledButton(
                      onPressed: () => onStart(buildStudy(s), s.name),
                      child: Text('Tutte (${s.questions.length})'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Studio per materia')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: db.subjects.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final s = db.subjects[i];
          return Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _choose(context, s),
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

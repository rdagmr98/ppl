import 'package:flutter/material.dart';
import 'models.dart';
import 'builder.dart';
import 'quiz_screen.dart';
import 'stats_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Quiz PPL(A)'),
          backgroundColor: theme.colorScheme.surface,
          flexibleSpace: const FlexibleSpaceBar(
            background: _HeaderArt(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ModeCard(
                icon: Icons.flight_takeoff,
                color: const Color(0xFF1E88E5),
                title: 'Esame completo',
                subtitle: '132 quesiti, distribuzione ufficiale ENAC',
                onTap: () =>
                    _start(buildExam(db), 'Esame completo', isExam: true),
              ),
              _ModeCard(
                icon: Icons.record_voice_over,
                color: const Color(0xFF26A69A),
                title: 'Esame + fonia inglese',
                subtitle: '152 quesiti (132 + 20 di comunicazioni EN)',
                onTap: () => _start(buildExam(db, withEnglish: true),
                    'Esame + inglese',
                    isExam: true),
              ),
              _ModeCard(
                icon: Icons.bolt,
                color: const Color(0xFFFFB300),
                title: 'Allenamento rapido',
                subtitle: '30 quesiti casuali da tutte le materie',
                onTap: () =>
                    _start(buildMixed(db, 30), 'Allenamento rapido'),
              ),
              _ModeCard(
                icon: Icons.menu_book,
                color: const Color(0xFF7E57C2),
                title: 'Studio per materia',
                subtitle: 'Scegli una materia e quante domande',
                onTap: () => _openSubjects(db),
              ),
              _ModeCard(
                icon: Icons.query_stats,
                color: const Color(0xFF00ACC1),
                title: 'Statistiche',
                subtitle: 'Sei pronto per l\'esame? Riepilogo e grafici',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
              ),
            ]),
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
      child: const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(right: 16, bottom: 56),
          child: Icon(Icons.flight, size: 64, color: Colors.white12),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
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
        separatorBuilder: (_, __) => const SizedBox(height: 8),
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

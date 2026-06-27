import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'builder.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final String title;
  final bool isExam;
  const QuizScreen({
    super.key,
    required this.questions,
    required this.title,
    this.isExam = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _correctColor = Color(0xFF2E7D32);
  static const _correctBorder = Color(0xFF69F0AE);
  static const _wrongColor = Color(0xFFB71C1C);
  static const _wrongBorder = Color(0xFFFF5252);

  int _index = 0;
  int? _selected;
  bool _locked = false;
  bool _advancing = false;
  int _correctCount = 0;
  final List<AnsweredQuestion> _answers = [];
  Timer? _timer;

  Question get _q => widget.questions[_index];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTap(int i) {
    if (_locked) return;
    final correct = i == _q.correct;
    setState(() {
      _selected = i;
      _locked = true;
      if (correct) _correctCount++;
    });
    if (correct) {
      HapticFeedback.lightImpact();
      _timer = Timer(const Duration(milliseconds: 480), _next);
    } else {
      HapticFeedback.heavyImpact();
      // resta sulla domanda: l'utente vede la corretta in verde e tocca per continuare
    }
  }

  void _next() {
    if (_advancing) return;
    _advancing = true;
    _timer?.cancel();
    _answers.add(AnsweredQuestion(_q, _selected ?? -1));
    if (_index >= widget.questions.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            answers: _answers,
            title: widget.title,
            isExam: widget.isExam,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _locked = false;
      _advancing = false;
    });
  }

  Future<void> _confirmQuit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uscire dalla prova?'),
        content: const Text('I progressi di questa sessione andranno persi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.questions.length;
    final wrongShown = _locked && _selected != _q.correct;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmQuit,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('Domanda ${_index + 1} di $total',
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF69F0AE), size: 18),
                    const SizedBox(width: 4),
                    Text('$_correctCount',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_index + (_locked ? 1 : 0)) / total,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        body: GestureDetector(
          // su risposta sbagliata: tocca ovunque per continuare
          onTap: wrongShown ? _next : null,
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _q.q,
                          style: const TextStyle(
                            fontSize: 21,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (int i = 0; i < _q.options.length; i++)
                          _OptionCard(
                            letter: String.fromCharCode(65 + i),
                            text: _q.options[i],
                            state: _stateFor(i),
                            onTap: () => _onTap(i),
                          ),
                      ],
                    ),
                  ),
                ),
                _bottomBar(wrongShown, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _OptState _stateFor(int i) {
    if (!_locked) return _OptState.idle;
    if (i == _q.correct) return _OptState.correct;
    if (i == _selected) return _OptState.wrong;
    return _OptState.muted;
  }

  Widget _bottomBar(bool wrongShown, ThemeData theme) {
    if (!wrongShown) {
      // spazio neutro per stabilità layout
      return const SizedBox(height: 64);
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('CONTINUA',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, muted }

class _OptionCard extends StatelessWidget {
  final String letter;
  final String text;
  final _OptState state;
  final VoidCallback onTap;
  const _OptionCard({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color border;
    Color fg = theme.colorScheme.onSurface;
    IconData? icon;
    Color? iconColor;

    switch (state) {
      case _OptState.idle:
        bg = theme.colorScheme.surfaceContainerHigh;
        border = theme.colorScheme.outlineVariant;
        break;
      case _OptState.correct:
        bg = _QuizScreenState._correctColor;
        border = _QuizScreenState._correctBorder;
        fg = Colors.white;
        icon = Icons.check_circle;
        iconColor = Colors.white;
        break;
      case _OptState.wrong:
        bg = _QuizScreenState._wrongColor;
        border = _QuizScreenState._wrongBorder;
        fg = Colors.white;
        icon = Icons.cancel;
        iconColor = Colors.white;
        break;
      case _OptState.muted:
        bg = theme.colorScheme.surfaceContainer;
        border = Colors.transparent;
        fg = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: state == _OptState.idle ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state == _OptState.idle
                        ? theme.colorScheme.primaryContainer
                        : Colors.white24,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: state == _OptState.idle
                          ? theme.colorScheme.onPrimaryContainer
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 16, height: 1.25, color: fg),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: iconColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

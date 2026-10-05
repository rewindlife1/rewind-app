import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/pillars.dart';
import '../../domain/questions.dart';
import '../../domain/scoring.dart';
import '../../domain/task_library.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  int _index = -1; // -1 = intro
  final Map<String, int> _answers = {};
  final Map<String, int> _picked = {}; // question id -> option index
  bool _saving = false;
  Map<Pillar, int>? _result;
  int? _overall;

  Future<void> _finish() async {
    setState(() => _saving = true);
    final pillars = Scoring.pillarScoresFromAnswers(_answers);
    final overall = Scoring.overall(pillars);
    try {
      final repo = ref.read(repoProvider);
      await repo.saveAssessment(answers: _answers, pillarScores: pillars, overall: overall);
      await repo.replacePlan(generatePlan(pillars));
      refreshAll(ref);
      setState(() {
        _result = pillars;
        _overall = overall;
      });
    } catch (e) {
      if (mounted) showSnack(context, 'Could not save your assessment: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _choose(Question q, int optionIndex) {
    setState(() {
      _answers[q.id] = q.options[optionIndex].points;
      _picked[q.id] = optionIndex;
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_index < kQuestions.length - 1) {
        setState(() => _index++);
      } else {
        _finish();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const RewindLogo(compact: true),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Exit', style: TextStyle(color: RC.muted)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _body(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_result != null) return _results(context);
    if (_saving) {
      return Column(
        key: const ValueKey('saving'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: RC.ink, strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Calculating your Longevity Score…', style: t.titleMedium),
        ],
      );
    }
    if (_index < 0) {
      return Column(
        key: const ValueKey('intro'),
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip2('About 4 minutes'),
          const SizedBox(height: 16),
          Text('Your REWIND assessment',
              style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text(
            '24 quick questions across the 8 dimensions of health and longevity. '
            'We’ll calculate your Longevity Score and build a daily plan around your biggest opportunities.',
            style: t.bodyLarge?.copyWith(color: RC.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in Pillar.values) Chip2(p.label, color: Colors.white),
          ]),
          const SizedBox(height: 32),
          FilledButton(onPressed: () => setState(() => _index = 0), child: const Text('Start assessment')),
        ],
      );
    }

    final q = kQuestions[_index];
    final selected = _picked[q.id];
    return Column(
      key: ValueKey(q.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(q.pillar.icon, size: 18, color: RC.muted),
          const SizedBox(width: 6),
          Text(q.pillar.label, style: const TextStyle(color: RC.muted, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${_index + 1} / ${kQuestions.length}', style: const TextStyle(color: RC.muted)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (_index + 1) / kQuestions.length,
            minHeight: 6,
            backgroundColor: RC.line,
            valueColor: const AlwaysStoppedAnimation(RC.ink),
          ),
        ),
        const SizedBox(height: 36),
        Text(q.prompt, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(children: [
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionTile(
                  label: q.options[i].label,
                  selected: selected == i,
                  onTap: () => _choose(q, i),
                ),
              ),
          ]),
        ),
        Row(children: [
          if (_index > 0)
            TextButton.icon(
              onPressed: () => setState(() => _index--),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(foregroundColor: RC.ink),
            ),
        ]),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pillars = _result!;
    final weak = Scoring.weakest(pillars);
    return ListView(
      key: const ValueKey('results'),
      children: [
        const SizedBox(height: 12),
        Center(child: ScoreRing(score: _overall!, size: 200)),
        const SizedBox(height: 12),
        Center(child: Chip2(scoreBand(_overall!))),
        const SizedBox(height: 20),
        Text('Your starting point', textAlign: TextAlign.center,
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Your plan focuses on ${weak[0].label} and ${weak[1].label} first. '
          'Complete it daily and watch your score climb.',
          textAlign: TextAlign.center,
          style: t.bodyLarge?.copyWith(color: RC.muted),
        ),
        const SizedBox(height: 24),
        RCard(
          child: Column(children: [
            for (final p in Pillar.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Icon(p.icon, size: 18),
                  const SizedBox(width: 10),
                  SizedBox(width: 140, child: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(child: PillarBar(value: pillars[p] ?? 0)),
                  const SizedBox(width: 12),
                  SizedBox(
                      width: 32,
                      child: Text('${pillars[p] ?? 0}',
                          textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        const Text(
          'Blood Biomarkers is estimated from your answers until your REWIND lab results are connected.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: RC.muted),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => context.go('/dashboard'), child: const Text('See my plan')),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? RC.lime : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? RC.ink : RC.line),
          ),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? RC.ink : RC.line),
          ]),
        ),
      ),
    );
  }
}

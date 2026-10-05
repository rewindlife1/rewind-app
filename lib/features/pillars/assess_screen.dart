import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/pillars.dart';
import '../../domain/task_library.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

/// Overview of all 8 dimensions with radar chart.
class AssessScreen extends ConsumerWidget {
  const AssessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final score = ref.watch(scoreProvider);
    return AsyncView<ScoreView?>(
      value: score,
      data: (s) {
        return PageBody(maxWidth: 960, children: [
          const SizedBox(height: 8),
          Text('Assess', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('The 8 dimensions of health and longevity.',
              style: t.titleMedium?.copyWith(color: RC.muted)),
          const SizedBox(height: 20),
          if (s == null)
            RCard(
              child: Column(children: [
                const Text('You haven’t taken your assessment yet.'),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () => context.go('/assessment'), child: const Text('Start assessment')),
              ]),
            )
          else ...[
            RCard(
              child: LayoutBuilder(builder: (context, c) {
                final radar = PillarRadar(scores: s.pillars, size: c.maxWidth > 600 ? 320 : c.maxWidth);
                final side = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ScoreRing(score: s.overall, size: 150),
                  const SizedBox(height: 16),
                  Text('Last assessed ${s.assessment.createdAt.month}/${s.assessment.createdAt.day}/${s.assessment.createdAt.year}',
                      style: const TextStyle(color: RC.muted)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: () => context.go('/assessment'), child: const Text('Retake assessment')),
                ]);
                return c.maxWidth > 600
                    ? Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [side, radar])
                    : Column(children: [radar, const SizedBox(height: 16), side]);
              }),
            ),
            const SizedBox(height: 16),
            for (final p in Pillar.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RCard(
                  onTap: () => context.go('/assess/${p.name}'),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: RC.bg, child: Icon(p.icon, color: RC.ink)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        PillarBar(value: s.pillars[p] ?? 0),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Text('${s.pillars[p] ?? 0}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const Icon(Icons.chevron_right, color: RC.muted),
                  ]),
                ),
              ),
          ],
        ]);
      },
    );
  }
}

/// Detail for one pillar: score, explanation, and tasks to add to the plan.
class PillarDetailScreen extends ConsumerWidget {
  const PillarDetailScreen({super.key, required this.pillarKey});
  final String pillarKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Pillar.fromKey(pillarKey);
    if (p == null) {
      return const Center(child: Text('Unknown dimension'));
    }
    final t = Theme.of(context).textTheme;
    final s = ref.watch(scoreProvider).valueOrNull;
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const [];
    final inPlan = tasks.map((x) => x.title).toSet();
    final value = s?.pillars[p];

    return PageBody(maxWidth: 760, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.go('/assess'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('All dimensions'),
          style: TextButton.styleFrom(foregroundColor: RC.ink),
        ),
      ),
      const SizedBox(height: 8),
      RCard(
        color: RC.ink,
        padding: const EdgeInsets.all(28),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(p.icon, color: RC.lime),
              const SizedBox(height: 12),
              Text(p.label,
                  style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(p.description, style: const TextStyle(color: Colors.white70, height: 1.5)),
              if (p == Pillar.biomarkers) ...[
                const SizedBox(height: 12),
                const Chip2('Estimated until lab results are connected'),
              ],
            ]),
          ),
          if (value != null) ...[
            const SizedBox(width: 16),
            ScoreRing(score: value, size: 120, label: 'Score', dark: true),
          ],
        ]),
      ),
      const SizedBox(height: 20),
      const SectionTitle('Actions that move this score'),
      for (final tpl in kTaskLibrary[p] ?? const <TaskTemplate>[])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RCard(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tpl.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(tpl.detail, style: const TextStyle(color: RC.muted)),
                ]),
              ),
              const SizedBox(width: 12),
              inPlan.contains(tpl.title)
                  ? const Chip2('In your plan')
                  : OutlinedButton(
                      onPressed: () async {
                        try {
                          await ref.read(repoProvider).addTask(tpl);
                          refreshActivity(ref);
                          if (context.mounted) showSnack(context, 'Added to your daily plan');
                        } catch (e) {
                          if (context.mounted) showSnack(context, 'Could not add: $e');
                        }
                      },
                      child: const Text('Add'),
                    ),
            ]),
          ),
        ),
    ]);
  }
}

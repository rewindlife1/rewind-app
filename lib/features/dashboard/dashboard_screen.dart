import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/pillars.dart';
import '../../domain/scoring.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(scoreProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    return RefreshIndicator(
      color: RC.ink,
      onRefresh: () async => refreshAll(ref),
      child: AsyncView<ScoreView?>(
        value: score,
        onRetry: () => refreshAll(ref),
        data: (s) {
          if (s == null) return _FirstRun(name: profile?.firstName ?? '');
          return _Dashboard(score: s, name: profile?.firstName ?? '');
        },
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

class _FirstRun extends StatelessWidget {
  const _FirstRun({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return PageBody(maxWidth: 760, children: [
      const SizedBox(height: 24),
      Text('${_greeting()}${name.isEmpty ? '' : ', $name'}.',
          style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 8),
      Text('Let’s find your starting point.', style: t.titleMedium?.copyWith(color: RC.muted)),
      const SizedBox(height: 24),
      RCard(
        color: RC.ink,
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Chip2('Step 1'),
          const SizedBox(height: 16),
          Text('Take your REWIND assessment',
              style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'REWIND measures 8 unique dimensions of health and longevity to give you a more complete, '
            'true Longevity Score — and a clear path to improve it.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: RC.lime, foregroundColor: RC.ink),
            onPressed: () => context.go('/assessment'),
            child: const Text('Start — about 4 minutes'),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            for (final p in Pillar.values)
              RCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(p.icon),
                  const Spacer(),
                  Text(p.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
          ],
        );
      }),
    ]);
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.score, required this.name});
  final ScoreView score;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width > 980;
    final weak = Scoring.weakest(score.pillars);

    final hero = RCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        ScoreRing(score: score.overall, size: 190),
        const SizedBox(height: 12),
        Chip2(scoreBand(score.overall)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _Stat(label: 'Day streak', value: '${score.streak}')),
          Expanded(child: _Stat(label: '7-day plan', value: '${(score.adherence7d * 100).round()}%')),
          Expanded(child: _Stat(label: 'Focus', value: weak.first.short)),
        ]),
      ]),
    );

    final tasks = const _TodayPlan();

    final pillars = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle('Your 8 dimensions',
          trailing: TextButton(
              onPressed: () => context.go('/assess'),
              child: const Text('Details', style: TextStyle(color: RC.ink)))),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            for (final p in Pillar.values)
              RCard(
                padding: const EdgeInsets.all(16),
                onTap: () => context.go('/assess/${p.name}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(p.icon, size: 20),
                    const Spacer(),
                    Text('${score.pillars[p] ?? 0}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ]),
                  const Spacer(),
                  Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  PillarBar(value: score.pillars[p] ?? 0),
                ]),
              ),
          ],
        );
      }),
    ]);

    return PageBody(children: [
      const SizedBox(height: 8),
      Text('${_greeting()}${name.isEmpty ? '' : ', $name'}.',
          style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text('Here’s your plan for today.', style: t.titleMedium?.copyWith(color: RC.muted)),
      const SizedBox(height: 20),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 340, child: hero),
          const SizedBox(width: 20),
          Expanded(child: tasks),
        ])
      else ...[
        hero,
        const SizedBox(height: 20),
        tasks,
      ],
      const SizedBox(height: 28),
      pillars,
      const SizedBox(height: 20),
      RCard(
        color: RC.limeSoft,
        onTap: () => context.go('/coach'),
        child: Row(children: [
          const CircleAvatar(
              backgroundColor: RC.ink, child: Icon(Icons.auto_awesome, color: RC.lime, size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Ask REWIND Coach how to raise your ${weak.first.label} score.',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.arrow_forward),
        ]),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: RC.muted)),
      ]);
}

class _TodayPlan extends ConsumerStatefulWidget {
  const _TodayPlan();

  @override
  ConsumerState<_TodayPlan> createState() => _TodayPlanState();
}

class _TodayPlanState extends ConsumerState<_TodayPlan> {
  final Set<String> _pending = {};

  Future<void> _toggle(RTask task, bool done) async {
    setState(() => _pending.add(task.id));
    try {
      await ref.read(repoProvider).setDone(task.id, DateTime.now(), done);
      refreshActivity(ref);
    } catch (e) {
      if (mounted) showSnack(context, 'Could not update: $e');
    } finally {
      if (mounted) setState(() => _pending.remove(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final logs = ref.watch(logsProvider);
    final today = dayKey(DateTime.now());

    return RCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: AsyncView<List<RTask>>(
        value: tasks,
        data: (list) {
          final doneIds = (logs.valueOrNull ?? const <TaskLog>[])
              .where((l) => l.day == today)
              .map((l) => l.taskId)
              .toSet();
          final doneCount = list.where((t) => doneIds.contains(t.id)).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionTitle('Today’s plan',
                trailing: Chip2('$doneCount of ${list.length} done')),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No tasks yet — retake your assessment to build a plan.',
                    style: TextStyle(color: RC.muted)),
              ),
            for (final task in list)
              _TaskRow(
                task: task,
                done: doneIds.contains(task.id),
                busy: _pending.contains(task.id),
                onChanged: (v) => _toggle(task, v),
              ),
          ]);
        },
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.done, required this.busy, required this.onChanged});
  final RTask task;
  final bool done;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: busy ? null : () => onChanged(!done),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? RC.lime : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: done ? RC.ink : RC.line, width: 1.5),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(strokeWidth: 2, color: RC.ink))
                : done
                    ? const Icon(Icons.check, size: 16, color: RC.ink)
                    : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? RC.muted : RC.ink,
                  )),
              if (task.detail != null) ...[
                const SizedBox(height: 2),
                Text(task.detail!, style: const TextStyle(color: RC.muted, fontSize: 13)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Chip2(task.pillar.short, color: RC.bg),
        ]),
      ),
    );
  }
}

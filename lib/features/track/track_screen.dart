import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final snaps = ref.watch(snapshotsProvider);
    final logs = ref.watch(logsProvider);
    final tasks = ref.watch(tasksProvider);
    final assessments = ref.watch(assessmentsProvider);

    return PageBody(maxWidth: 960, children: [
      const SizedBox(height: 8),
      Text('Track', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Your Longevity Score over time.', style: t.titleMedium?.copyWith(color: RC.muted)),
      const SizedBox(height: 20),
      RCard(
        child: AsyncView<List<ScoreSnapshot>>(
          value: snaps,
          data: (list) {
            if (list.isEmpty) {
              return Column(children: [
                const SectionTitle('Longevity Score'),
                const Text('Take your assessment to start tracking.', style: TextStyle(color: RC.muted)),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => context.go('/assessment'), child: const Text('Start assessment')),
              ]);
            }
            final first = list.first.overall;
            final last = list.last.overall;
            final delta = last - first;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionTitle('Longevity Score',
                  trailing: Chip2(delta >= 0 ? '+$delta since ${list.first.day}' : '$delta since ${list.first.day}',
                      color: delta >= 0 ? RC.limeSoft : const Color(0xFFFDECEC))),
              Text('$last', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(height: 16),
              ScoreLineChart(values: [for (final s in list) s.overall]),
            ]);
          },
        ),
      ),
      const SizedBox(height: 16),
      RCard(
        child: Builder(builder: (context) {
          final ls = logs.valueOrNull ?? const <TaskLog>[];
          final taskCount = (tasks.valueOrNull ?? const []).length;
          final now = DateTime.now();
          final days = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle('Plan completion — last 7 days'),
            SizedBox(
              height: 150,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final d in days)
                  Expanded(
                    child: Builder(builder: (context) {
                      final count = ls.where((l) => l.day == dayKey(d)).length;
                      final frac = taskCount == 0 ? 0.0 : (count / taskCount).clamp(0.0, 1.0);
                      return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text('$count', style: const TextStyle(fontSize: 12, color: RC.muted)),
                        const SizedBox(height: 4),
                        Container(
                          height: 4 + 96 * frac,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: frac >= 1 ? RC.lime : RC.ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_weekdays[d.weekday - 1],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]);
                    }),
                  ),
              ]),
            ),
          ]);
        }),
      ),
      const SizedBox(height: 16),
      RCard(
        child: AsyncView(
          value: assessments,
          data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionTitle('Assessments',
                trailing: TextButton(
                    onPressed: () => context.go('/assessment'),
                    child: const Text('Retake', style: TextStyle(color: RC.ink)))),
            if (list.isEmpty) const Text('None yet.', style: TextStyle(color: RC.muted)),
            for (final a in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: RC.limeSoft,
                  child: Text('${a.overall}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: RC.ink)),
                ),
                title: Text(dayKey(a.createdAt)),
                subtitle: const Text('Assessment score'),
              ),
          ]),
        ),
      ),
    ]);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../domain/pillars.dart';
import '../domain/scoring.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authChangesProvider = StreamProvider<AuthState>(
    (ref) => ref.watch(supabaseProvider).auth.onAuthStateChange);

/// Current user; rebuilds dependants on every auth change.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authChangesProvider);
  return ref.watch(supabaseProvider).auth.currentUser;
});

final repoProvider = Provider<RewindRepository>(
    (ref) => RewindRepository(ref.watch(supabaseProvider)));

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(repoProvider).profile();
});

final latestAssessmentProvider = FutureProvider<Assessment?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(repoProvider).latestAssessment();
});

final assessmentsProvider = FutureProvider<List<Assessment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(repoProvider).assessments();
});

final tasksProvider = FutureProvider<List<RTask>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(repoProvider).activeTasks();
});

/// Task completions for the last 30 days.
final logsProvider = FutureProvider<List<TaskLog>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref
      .watch(repoProvider)
      .logsSince(DateTime.now().subtract(const Duration(days: 30)));
});

final snapshotsProvider = FutureProvider<List<ScoreSnapshot>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  // Make sure today's snapshot is written first.
  await ref.watch(scoreProvider.future);
  return ref.watch(repoProvider).snapshots();
});

final coachMessagesProvider = FutureProvider<List<CoachMessage>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(repoProvider).coachMessages();
});

class ScoreView {
  ScoreView({
    required this.overall,
    required this.pillars,
    required this.assessment,
    required this.adherence7d,
    required this.streak,
  });
  final int overall;
  final Map<Pillar, int> pillars;
  final Assessment assessment;
  final double adherence7d;
  final int streak;
}

/// Live Longevity Score = latest assessment + last-7-day plan adherence.
final scoreProvider = FutureProvider<ScoreView?>((ref) async {
  final assessment = await ref.watch(latestAssessmentProvider.future);
  if (assessment == null) return null;
  final tasks = await ref.watch(tasksProvider.future);
  final logs = await ref.watch(logsProvider.future);

  final now = DateTime.now();
  final weekDays = {
    for (var i = 0; i < 7; i++) dayKey(now.subtract(Duration(days: i)))
  };
  final taskPillar = {for (final t in tasks) t.id: t.pillar};

  final tasksByPillar = <Pillar, int>{};
  for (final t in tasks) {
    tasksByPillar[t.pillar] = (tasksByPillar[t.pillar] ?? 0) + 1;
  }
  final doneByPillar = <Pillar, int>{};
  var doneWeek = 0;
  for (final l in logs) {
    final p = taskPillar[l.taskId];
    if (p == null || !weekDays.contains(l.day)) continue;
    doneByPillar[p] = (doneByPillar[p] ?? 0) + 1;
    doneWeek++;
  }

  final adherence = Scoring.adherence(
      tasksByPillar: tasksByPillar, completionsByPillar: doneByPillar);
  final pillars = Scoring.withActivity(assessment.pillarScores, adherence);
  final overall = Scoring.overall(pillars);

  // Streak: consecutive days (ending today or yesterday) with ≥1 completion.
  final activeDays = logs.map((l) => l.day).toSet();
  var streak = 0;
  var cursor = now;
  if (!activeDays.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  while (activeDays.contains(dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Persist today's score for history (best effort).
  try {
    await ref.read(repoProvider).upsertSnapshot(now, overall, pillars);
  } catch (_) {}

  return ScoreView(
    overall: overall,
    pillars: pillars,
    assessment: assessment,
    adherence7d: tasks.isEmpty ? 0.0 :(doneWeek / (tasks.length * 7)).clamp(0.0, 1.0),
    streak: streak,
  );
});

/// Refresh everything that depends on plan activity.
void refreshActivity(WidgetRef ref) {
  ref.invalidate(logsProvider);
  ref.invalidate(tasksProvider);
  ref.invalidate(scoreProvider);
  ref.invalidate(snapshotsProvider);
}

/// Refresh everything after a new assessment.
void refreshAll(WidgetRef ref) {
  ref.invalidate(latestAssessmentProvider);
  ref.invalidate(assessmentsProvider);
  refreshActivity(ref);
}

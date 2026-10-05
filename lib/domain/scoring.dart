import 'dart:math' as math;

import 'pillars.dart';
import 'questions.dart';

/// REWIND Longevity Score.
///
/// Each pillar is scored 0–100:
///   * up to 85 points come from the assessment (what you measure), and
///   * up to 15 points come from 7-day plan adherence (what you do).
/// The overall score is the weighted average of the 8 pillars.
class Scoring {
  static const assessmentShare = 0.85;
  static const activityShare = 15.0;

  /// Raw 0–100 pillar scores from assessment answers (questionId -> points 0..4).
  static Map<Pillar, int> pillarScoresFromAnswers(Map<String, int> answers,
      {List<Question> questions = kQuestions}) {
    final result = <Pillar, int>{};
    for (final p in Pillar.values) {
      final qs = questions.where((q) => q.pillar == p).toList();
      if (qs.isEmpty) {
        result[p] = 0;
        continue;
      }
      var got = 0;
      var max = 0;
      for (final q in qs) {
        final best = q.options.map((o) => o.points).reduce(math.max);
        max += best;
        got += (answers[q.id] ?? 0).clamp(0, best);
      }
      result[p] = max == 0 ? 0 : ((got / max) * 100).round();
    }
    return result;
  }

  /// Weighted overall 0–100.
  static int overall(Map<Pillar, int> pillars) {
    var total = 0.0;
    for (final p in Pillar.values) {
      total += (pillars[p] ?? 0) * p.weight;
    }
    return total.round().clamp(0, 100);
  }

  /// Combine assessment results with plan adherence (0..1 per pillar).
  static Map<Pillar, int> withActivity(
      Map<Pillar, int> assessment, Map<Pillar, double> adherence) {
    return {
      for (final p in Pillar.values)
        p: ((assessment[p] ?? 0) * assessmentShare +
                (adherence[p] ?? 0.0).clamp(0.0, 1.0) * activityShare)
            .round()
            .clamp(0, 100),
    };
  }

  /// Adherence per pillar over [days] days.
  /// [tasksByPillar] = number of active daily tasks in each pillar.
  /// [completionsByPillar] = completed task-days in the window per pillar.
  /// Pillars with no tasks inherit the overall adherence rate so members
  /// are never penalised for what the plan didn't ask of them.
  static Map<Pillar, double> adherence({
    required Map<Pillar, int> tasksByPillar,
    required Map<Pillar, int> completionsByPillar,
    int days = 7,
  }) {
    final totalTasks = tasksByPillar.values.fold<int>(0, (a, b) => a + b);
    final totalDone = completionsByPillar.values.fold<int>(0, (a, b) => a + b);
    final overallRate =
        totalTasks == 0 ? 0.0 : (totalDone / (totalTasks * days)).clamp(0.0, 1.0);
    return {
      for (final p in Pillar.values)
        p: (tasksByPillar[p] ?? 0) == 0
            ? overallRate
            : ((completionsByPillar[p] ?? 0) / (tasksByPillar[p]! * days))
                .clamp(0.0, 1.0),
    };
  }

  /// Pillars ordered weakest first.
  static List<Pillar> weakest(Map<Pillar, int> pillars) {
    final list = Pillar.values.toList();
    list.sort((a, b) => (pillars[a] ?? 0).compareTo(pillars[b] ?? 0));
    return list;
  }
}

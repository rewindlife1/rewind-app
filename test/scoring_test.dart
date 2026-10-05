import 'package:flutter_test/flutter_test.dart';
import 'package:rewind/domain/pillars.dart';
import 'package:rewind/domain/questions.dart';
import 'package:rewind/domain/scoring.dart';
import 'package:rewind/domain/task_library.dart';
import 'package:rewind/domain/coach_engine.dart';

Map<String, int> _allBest() => {
      for (final q in kQuestions)
        q.id: q.options.map((o) => o.points).reduce((a, b) => a > b ? a : b)
    };

void main() {
  test('pillar weights sum to 1', () {
    final sum = Pillar.values.fold<double>(0, (a, p) => a + p.weight);
    expect(sum, closeTo(1.0, 1e-9));
  });

  test('every pillar has exactly 3 questions and unique ids', () {
    for (final p in Pillar.values) {
      expect(kQuestions.where((q) => q.pillar == p).length, 3, reason: p.name);
    }
    expect(kQuestions.map((q) => q.id).toSet().length, kQuestions.length);
  });

  test('best answers score 100, worst score 0', () {
    final best = Scoring.pillarScoresFromAnswers(_allBest());
    expect(best.values.every((v) => v == 100), isTrue);
    expect(Scoring.overall(best), 100);

    final worst = Scoring.pillarScoresFromAnswers({for (final q in kQuestions) q.id: 0});
    expect(worst.values.every((v) => v == 0), isTrue);
    expect(Scoring.overall(worst), 0);
  });

  test('activity contributes up to 15 points', () {
    final base = {for (final p in Pillar.values) p: 100};
    final none = Scoring.withActivity(base, {});
    expect(none.values.every((v) => v == 85), isTrue);
    final full = Scoring.withActivity(base, {for (final p in Pillar.values) p: 1.0});
    expect(full.values.every((v) => v == 100), isTrue);
  });

  test('adherence inherits overall rate for pillars without tasks', () {
    final a = Scoring.adherence(
      tasksByPillar: {Pillar.exercise: 1},
      completionsByPillar: {Pillar.exercise: 7},
    );
    expect(a[Pillar.exercise], 1.0);
    expect(a[Pillar.mindset], 1.0);
  });

  test('plan targets weakest pillars', () {
    final scores = {for (final p in Pillar.values) p: 80};
    scores[Pillar.community] = 10;
    scores[Pillar.routines] = 20;
    final plan = generatePlan(scores);
    expect(plan.length, 6);
    expect(plan.where((t) => t.pillar == Pillar.community).length, 2);
    expect(plan.where((t) => t.pillar == Pillar.routines).length, 2);
  });

  test('coach explains score', () {
    final scores = {for (final p in Pillar.values) p: 70};
    scores[Pillar.mindset] = 30;
    final r = CoachEngine.reply(
        message: 'explain my score', turn: 0, pillarScores: scores, overall: 64);
    expect(r, contains('64'));
    expect(r, contains('Mindset'));
  });
}

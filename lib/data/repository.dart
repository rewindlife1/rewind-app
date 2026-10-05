import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/pillars.dart';
import '../domain/task_library.dart';
import 'models.dart';

/// All reads/writes to Supabase. Every table is protected by row-level
/// security so a member can only ever touch their own rows.
class RewindRepository {
  RewindRepository(this.db);
  final SupabaseClient db;

  String get uid {
    final u = db.auth.currentUser;
    if (u == null) throw StateError('Not signed in');
    return u.id;
  }

  // ---------- Profile ----------
  Future<Profile?> profile() async {
    final row = await db.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<void> updateName(String fullName) async {
    await db.from('profiles').upsert({'id': uid, 'full_name': fullName});
  }

  // ---------- Assessments ----------
  Future<Assessment?> latestAssessment() async {
    final row = await db
        .from('assessments')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Assessment.fromJson(row);
  }

  Future<List<Assessment>> assessments() async {
    final rows = await db
        .from('assessments')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return rows.map(Assessment.fromJson).toList();
  }

  Future<Assessment> saveAssessment({
    required Map<String, int> answers,
    required Map<Pillar, int> pillarScores,
    required int overall,
  }) async {
    final row = await db
        .from('assessments')
        .insert({
          'user_id': uid,
          'answers': answers,
          'pillar_scores': pillarMapToJson(pillarScores),
          'overall': overall,
        })
        .select()
        .single();
    return Assessment.fromJson(row);
  }

  // ---------- Plan / tasks ----------
  Future<List<RTask>> activeTasks() async {
    final rows = await db
        .from('tasks')
        .select()
        .eq('user_id', uid)
        .eq('active', true)
        .order('created_at');
    return rows.map(RTask.fromJson).toList();
  }

  /// Retire the current plan and create a new one.
  Future<void> replacePlan(List<TaskTemplate> plan) async {
    await db.from('tasks').update({'active': false}).eq('user_id', uid).eq('active', true);
    if (plan.isEmpty) return;
    await db.from('tasks').insert([
      for (final t in plan)
        {
          'user_id': uid,
          'pillar': t.pillar.name,
          'title': t.title,
          'detail': t.detail,
        }
    ]);
  }

  Future<void> addTask(TaskTemplate t) async {
    await db.from('tasks').insert({
      'user_id': uid,
      'pillar': t.pillar.name,
      'title': t.title,
      'detail': t.detail,
    });
  }

  Future<void> retireTask(String taskId) async {
    await db.from('tasks').update({'active': false}).eq('id', taskId).eq('user_id', uid);
  }

  Future<List<TaskLog>> logsSince(DateTime since) async {
    final rows = await db
        .from('task_logs')
        .select('task_id, day')
        .eq('user_id', uid)
        .gte('day', dayKey(since));
    return rows.map(TaskLog.fromJson).toList();
  }

  Future<void> setDone(String taskId, DateTime day, bool done) async {
    final d = dayKey(day);
    if (done) {
      await db.from('task_logs').upsert(
        {'user_id': uid, 'task_id': taskId, 'day': d},
        onConflict: 'task_id,day',
      );
    } else {
      await db.from('task_logs').delete().eq('task_id', taskId).eq('day', d).eq('user_id', uid);
    }
  }

  // ---------- Score history ----------
  Future<void> upsertSnapshot(DateTime day, int overall, Map<Pillar, int> pillars) async {
    await db.from('score_snapshots').upsert(
      {
        'user_id': uid,
        'day': dayKey(day),
        'overall': overall,
        'pillar_scores': pillarMapToJson(pillars),
      },
      onConflict: 'user_id,day',
    );
  }

  Future<List<ScoreSnapshot>> snapshots({int days = 90}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await db
        .from('score_snapshots')
        .select()
        .eq('user_id', uid)
        .gte('day', dayKey(since))
        .order('day');
    return rows.map(ScoreSnapshot.fromJson).toList();
  }

  // ---------- REWIND Coach ----------
  Future<List<CoachMessage>> coachMessages() async {
    final rows = await db
        .from('coach_messages')
        .select()
        .eq('user_id', uid)
        .order('created_at')
        .limit(200);
    return rows.map(CoachMessage.fromJson).toList();
  }

  Future<void> addCoachMessage(String role, String body) async {
    await db.from('coach_messages').insert({'user_id': uid, 'role': role, 'body': body});
  }
}

import '../domain/pillars.dart';

String dayKey(DateTime d) {
  final l = DateTime(d.year, d.month, d.day);
  final m = l.month.toString().padLeft(2, '0');
  final dd = l.day.toString().padLeft(2, '0');
  return '${l.year}-$m-$dd';
}

Map<Pillar, int> pillarMapFromJson(dynamic json) {
  final out = <Pillar, int>{};
  if (json is Map) {
    json.forEach((k, v) {
      final p = Pillar.fromKey(k.toString());
      if (p != null && v is num) out[p] = v.round();
    });
  }
  return out;
}

Map<String, int> pillarMapToJson(Map<Pillar, int> m) =>
    {for (final e in m.entries) e.key.name: e.value};

class Profile {
  Profile({required this.id, this.fullName, this.membership = 'trial'});
  final String id;
  final String? fullName;
  final String membership;

  String get firstName {
    final n = (fullName ?? '').trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = (fullName ?? '').trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        fullName: j['full_name'] as String?,
        membership: (j['membership'] as String?) ?? 'trial',
      );
}

class Assessment {
  Assessment({
    required this.id,
    required this.answers,
    required this.pillarScores,
    required this.overall,
    required this.createdAt,
  });
  final String id;
  final Map<String, int> answers;
  final Map<Pillar, int> pillarScores;
  final int overall;
  final DateTime createdAt;

  factory Assessment.fromJson(Map<String, dynamic> j) {
    final raw = j['answers'];
    final answers = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) answers[k.toString()] = v.round();
      });
    }
    return Assessment(
      id: j['id'] as String,
      answers: answers,
      pillarScores: pillarMapFromJson(j['pillar_scores']),
      overall: (j['overall'] as num).round(),
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    );
  }
}

class RTask {
  RTask({required this.id, required this.pillar, required this.title, this.detail});
  final String id;
  final Pillar pillar;
  final String title;
  final String? detail;

  factory RTask.fromJson(Map<String, dynamic> j) => RTask(
        id: j['id'] as String,
        pillar: Pillar.fromKey(j['pillar'] as String) ?? Pillar.routines,
        title: j['title'] as String,
        detail: j['detail'] as String?,
      );
}

class TaskLog {
  TaskLog({required this.taskId, required this.day});
  final String taskId;
  final String day; // yyyy-MM-dd

  factory TaskLog.fromJson(Map<String, dynamic> j) =>
      TaskLog(taskId: j['task_id'] as String, day: j['day'] as String);
}

class ScoreSnapshot {
  ScoreSnapshot({required this.day, required this.overall, required this.pillars});
  final String day;
  final int overall;
  final Map<Pillar, int> pillars;

  factory ScoreSnapshot.fromJson(Map<String, dynamic> j) => ScoreSnapshot(
        day: j['day'] as String,
        overall: (j['overall'] as num).round(),
        pillars: pillarMapFromJson(j['pillar_scores']),
      );
}

class CoachMessage {
  CoachMessage({required this.role, required this.body, required this.createdAt});
  final String role; // 'user' | 'coach'
  final String body;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory CoachMessage.fromJson(Map<String, dynamic> j) => CoachMessage(
        role: j['role'] as String,
        body: j['body'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

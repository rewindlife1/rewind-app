import 'pillars.dart';
import 'scoring.dart';

/// REWIND Coach — v1 rules engine.
///
/// Answers from the member's own scores and plan. Designed so the reply
/// function can later be swapped for a server-side model (Supabase Edge
/// Function) without changing the UI.
class CoachEngine {
  static const _keywords = <Pillar, List<String>>{
    Pillar.biomarkers: ['blood', 'lab', 'biomarker', 'cholesterol', 'apob', 'a1c', 'glucose', 'crp', 'test', 'quest'],
    Pillar.toxins: ['toxin', 'water', 'plastic', 'alcohol', 'drink', 'product', 'air', 'mold'],
    Pillar.mindset: ['stress', 'anxious', 'anxiety', 'meditat', 'breath', 'mind', 'calm', 'focus'],
    Pillar.community: ['friend', 'lonely', 'family', 'community', 'social', 'connect'],
    Pillar.nutrition: ['eat', 'food', 'diet', 'protein', 'sugar', 'meal', 'nutrition', 'fast', 'weight'],
    Pillar.supplementation: ['supplement', 'vitamin', 'creatine', 'omega', 'magnesium', 'stack', 'peptide'],
    Pillar.exercise: ['workout', 'exercise', 'lift', 'strength', 'run', 'cardio', 'steps', 'gym', 'muscle'],
    Pillar.routines: ['sleep', 'sauna', 'cold', 'plunge', 'red light', 'hyperbaric', 'sun', 'tired', 'energy'],
  };

  static const _advice = <Pillar, List<String>>{
    Pillar.biomarkers: [
      'Your blood is the foundation of your score. If it has been more than 6 months, a full panel is the single best next step — and REWIND lab testing is on the way.',
      'Three numbers to know: ApoB (heart), HbA1c (metabolic) and hs-CRP (inflammation). Track them and you will see what is really changing.',
    ],
    Pillar.toxins: [
      'Start with the easy wins: filter your water, swap one product a week for a clean alternative, and keep alcohol to a minimum.',
      'Your home is your biggest exposure. Open windows daily, use a HEPA filter in the bedroom, and avoid heating food in plastic.',
    ],
    Pillar.mindset: [
      'Five minutes of box breathing lowers stress fast: inhale 4, hold 4, exhale 4, hold 4. Stack it onto something you already do, like your morning coffee.',
      'Chronic stress ages you. A daily 10-minute practice — meditation, journaling or a quiet walk — is one of the highest-return habits you can build.',
    ],
    Pillar.community: [
      'Strong relationships are one of the most powerful predictors of a long life. Schedule one real conversation a day — a call, a walk, a meal.',
      'Join something that meets weekly: a run club, a class, a faith community. Consistency of connection matters more than size.',
    ],
    Pillar.nutrition: [
      'Anchor every meal with protein — aim for about 30g — then fill the plate with plants. Most people under-eat protein as they age.',
      'Cut added sugar and stop eating about 3 hours before bed. Those two changes improve glucose, sleep and energy within weeks.',
    ],
    Pillar.supplementation: [
      'Cover the foundations first: vitamin D, omega-3, magnesium and creatine. Then personalise the stack once you have bloodwork.',
      'The best stack is the one you take every day. Keep it simple, keep it visible, and re-test to see what actually moves.',
    ],
    Pillar.exercise: [
      'Strength training 2–3 times a week is non-negotiable for longevity. Muscle protects your metabolism, bones and independence.',
      'Build your base with zone 2 cardio — a pace where you can talk — for 150 minutes a week, plus daily steps.',
    ],
    Pillar.routines: [
      'Sleep is the multiplier for everything else. Same bedtime, cool dark room, no screens for 30 minutes before bed.',
      'Get morning sunlight within an hour of waking and add one recovery ritual — sauna, cold plunge or red light — a few times a week.',
    ],
  };

  static String reply({
    required String message,
    required int turn,
    String? firstName,
    Map<Pillar, int>? pillarScores,
    int? overall,
  }) {
    final m = message.toLowerCase();
    final name = (firstName == null || firstName.isEmpty) ? '' : ', $firstName';

    if (m.contains('score') && pillarScores != null && overall != null) {
      final weak = Scoring.weakest(pillarScores);
      return 'Your REWIND Longevity Score is $overall (${scoreBand(overall)})$name. '
          'Your biggest opportunities are ${weak[0].label} (${pillarScores[weak[0]]}) and '
          '${weak[1].label} (${pillarScores[weak[1]]}). Your daily plan is built around those two — '
          'complete it consistently and your score will climb.';
    }

    for (final entry in _keywords.entries) {
      if (entry.value.any(m.contains)) {
        final tips = _advice[entry.key]!;
        final tip = tips[turn % tips.length];
        final s = pillarScores?[entry.key];
        final prefix = s == null ? '' : 'Your ${entry.key.label} score is $s. ';
        return '$prefix$tip';
      }
    }

    if (pillarScores != null) {
      final weakest = Scoring.weakest(pillarScores).first;
      final tips = _advice[weakest]!;
      return 'Good question$name. The biggest lever for you right now is ${weakest.label}. '
          '${tips[turn % tips.length]}';
    }

    return 'I’m your REWIND Coach$name. Take your assessment first so I can coach you from your own numbers.';
  }
}

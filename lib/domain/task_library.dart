import 'pillars.dart';
import 'scoring.dart';

class TaskTemplate {
  const TaskTemplate(this.pillar, this.title, this.detail);
  final Pillar pillar;
  final String title;
  final String detail;
}

const Map<Pillar, List<TaskTemplate>> kTaskLibrary = {
  Pillar.biomarkers: [
    TaskTemplate(Pillar.biomarkers, 'Log one biomarker you know',
        'Add a number from your last labs — ApoB, HbA1c, hs-CRP, vitamin D or testosterone.'),
    TaskTemplate(Pillar.biomarkers, 'Check your resting heart rate',
        'Take it first thing this morning. Trends matter more than any single day.'),
    TaskTemplate(Pillar.biomarkers, '10-minute walk after your biggest meal',
        'Post-meal walking measurably flattens glucose spikes.'),
  ],
  Pillar.toxins: [
    TaskTemplate(Pillar.toxins, 'Swap one product for a clean alternative',
        'Start with what touches your skin most — lotion, deodorant or fragrance.'),
    TaskTemplate(Pillar.toxins, 'Drink filtered water only today',
        'Skip single-use plastic bottles where you can.'),
    TaskTemplate(Pillar.toxins, 'Alcohol-free day', 'Your liver, sleep and HRV will thank you.'),
    TaskTemplate(Pillar.toxins, 'Open the windows for 15 minutes',
        'Indoor air is often more polluted than outdoor air.'),
  ],
  Pillar.mindset: [
    TaskTemplate(Pillar.mindset, '5 minutes of box breathing',
        'Inhale 4, hold 4, exhale 4, hold 4. Repeat.'),
    TaskTemplate(Pillar.mindset, '10-minute meditation', 'Quiet room, eyes closed, just breathe.'),
    TaskTemplate(Pillar.mindset, 'Write 3 things you’re grateful for',
        'Gratitude is one of the most studied levers for wellbeing.'),
  ],
  Pillar.community: [
    TaskTemplate(Pillar.community, 'Call someone you love',
        'A real conversation — not a text.'),
    TaskTemplate(Pillar.community, 'Share a meal with someone',
        'Eat together, phones away.'),
    TaskTemplate(Pillar.community, 'Reach out to an old friend',
        'One message to someone you haven’t talked to in months.'),
  ],
  Pillar.nutrition: [
    TaskTemplate(Pillar.nutrition, '30g protein at breakfast',
        'Eggs, Greek yogurt, a protein shake — start strong.'),
    TaskTemplate(Pillar.nutrition, 'Eat 5 different plants today',
        'Variety feeds a healthier gut microbiome.'),
    TaskTemplate(Pillar.nutrition, 'No added sugar today', 'Read the labels — it hides everywhere.'),
    TaskTemplate(Pillar.nutrition, 'Stop eating 3 hours before bed',
        'Better sleep, better glucose control.'),
  ],
  Pillar.supplementation: [
    TaskTemplate(Pillar.supplementation, 'Take your daily stack',
        'Consistency beats intensity.'),
    TaskTemplate(Pillar.supplementation, '5g creatine',
        'One of the most researched supplements for muscle and brain.'),
    TaskTemplate(Pillar.supplementation, 'Omega-3 with a meal',
        'Take with fat for better absorption.'),
  ],
  Pillar.exercise: [
    TaskTemplate(Pillar.exercise, '30 minutes of strength training',
        'Muscle is the organ of longevity.'),
    TaskTemplate(Pillar.exercise, '8,000 steps', 'Walk calls, take the stairs, park far away.'),
    TaskTemplate(Pillar.exercise, '20 minutes of zone 2 cardio',
        'A pace where you can still hold a conversation.'),
    TaskTemplate(Pillar.exercise, '2-minute dead hang or farmer carry',
        'Grip strength is one of the strongest predictors of longevity.'),
  ],
  Pillar.routines: [
    TaskTemplate(Pillar.routines, 'Morning sunlight — 10 minutes',
        'Within an hour of waking. Sets your circadian clock.'),
    TaskTemplate(Pillar.routines, 'In bed by 10:30pm', 'Aim for 7–8 hours of sleep.'),
    TaskTemplate(Pillar.routines, 'Sauna, cold plunge or red light',
        'Any one counts. Hormesis builds resilience.'),
    TaskTemplate(Pillar.routines, 'No screens 30 minutes before bed',
        'Read, stretch or talk instead.'),
  ],
};

/// Build a personalised daily plan: 2 tasks each from the two weakest pillars,
/// 1 task each from the next two. Six tasks total.
List<TaskTemplate> generatePlan(Map<Pillar, int> pillarScores) {
  final order = Scoring.weakest(pillarScores);
  final plan = <TaskTemplate>[];
  for (var i = 0; i < 4 && i < order.length; i++) {
    final take = i < 2 ? 2 : 1;
    plan.addAll((kTaskLibrary[order[i]] ?? const []).take(take));
  }
  return plan;
}

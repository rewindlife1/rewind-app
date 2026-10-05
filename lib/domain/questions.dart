import 'pillars.dart';

class AnswerOption {
  const AnswerOption(this.label, this.points);
  final String label;

  /// 0 (worst) – 4 (best).
  final int points;
}

class Question {
  const Question(this.id, this.pillar, this.prompt, this.options, {this.hint});
  final String id;
  final Pillar pillar;
  final String prompt;
  final String? hint;
  final List<AnswerOption> options;
}

const _freq = [
  AnswerOption('Never', 0),
  AnswerOption('Rarely', 1),
  AnswerOption('1–2 times a week', 2),
  AnswerOption('3–5 times a week', 3),
  AnswerOption('Almost every day', 4),
];

/// The REWIND initial assessment — 3 questions per pillar, 24 total.
const List<Question> kQuestions = [
  // Blood Biomarkers
  Question('bio_panel', Pillar.biomarkers, 'When was your last full blood panel?', [
    AnswerOption('Never / can’t remember', 0),
    AnswerOption('More than 3 years ago', 1),
    AnswerOption('1–3 years ago', 2),
    AnswerOption('6–12 months ago', 3),
    AnswerOption('Within the last 6 months', 4),
  ]),
  Question('bio_flags', Pillar.biomarkers, 'Were any markers flagged out of range?', [
    AnswerOption('Several were flagged', 0),
    AnswerOption('One or two were flagged', 2),
    AnswerOption('I don’t know', 1),
    AnswerOption('Nothing was flagged', 4),
  ]),
  Question('bio_advanced', Pillar.biomarkers,
      'Do you know your ApoB, HbA1c or hs-CRP numbers?', [
    AnswerOption('I haven’t heard of them', 0),
    AnswerOption('I’ve heard of them, never tested', 1),
    AnswerOption('I know one of them', 2),
    AnswerOption('I know two of them', 3),
    AnswerOption('I track all three', 4),
  ]),

  // Toxins
  Question('tox_products', Pillar.toxins,
      'How carefully do you choose personal care products (fragrance-free, clean ingredients)?', [
    AnswerOption('I don’t think about it', 0),
    AnswerOption('Occasionally', 1),
    AnswerOption('Some of my products', 2),
    AnswerOption('Most of my products', 3),
    AnswerOption('All of them, deliberately', 4),
  ]),
  Question('tox_home', Pillar.toxins, 'At home, do you filter your water and air?', [
    AnswerOption('Neither', 0),
    AnswerOption('One of them, basic', 2),
    AnswerOption('Both, basic filters', 3),
    AnswerOption('Both, high quality', 4),
  ]),
  Question('tox_alcohol', Pillar.toxins, 'How many alcoholic drinks do you have per week?', [
    AnswerOption('15 or more', 0),
    AnswerOption('8–14', 1),
    AnswerOption('4–7', 2),
    AnswerOption('1–3', 3),
    AnswerOption('None', 4),
  ]),

  // Mindset
  Question('mind_stress', Pillar.mindset, 'How would you rate your stress most days?', [
    AnswerOption('Overwhelming', 0),
    AnswerOption('High', 1),
    AnswerOption('Moderate', 2),
    AnswerOption('Manageable', 3),
    AnswerOption('Calm and in control', 4),
  ]),
  Question('mind_practice', Pillar.mindset,
      'How often do you practice breathwork, meditation or journaling?', _freq),
  Question('mind_purpose', Pillar.mindset,
      'How strongly do you feel a sense of purpose in your life?', [
    AnswerOption('Not at all', 0),
    AnswerOption('A little', 1),
    AnswerOption('Somewhat', 2),
    AnswerOption('Mostly', 3),
    AnswerOption('Deeply', 4),
  ]),

  // Community
  Question('com_friends', Pillar.community,
      'How often do you spend real time with friends or family?', _freq),
  Question('com_close', Pillar.community,
      'How many people could you call at 2am in a crisis?', [
    AnswerOption('No one', 0),
    AnswerOption('One', 2),
    AnswerOption('Two or three', 3),
    AnswerOption('Four or more', 4),
  ]),
  Question('com_group', Pillar.community,
      'Are you part of a group — team, faith community, club, class?', [
    AnswerOption('No', 0),
    AnswerOption('Occasionally', 2),
    AnswerOption('Yes, regularly', 4),
  ]),

  // Nutrition
  Question('nut_whole', Pillar.nutrition,
      'How much of your diet is whole, minimally processed food?', [
    AnswerOption('Very little', 0),
    AnswerOption('About a quarter', 1),
    AnswerOption('About half', 2),
    AnswerOption('Most of it', 3),
    AnswerOption('Almost all of it', 4),
  ]),
  Question('nut_protein', Pillar.nutrition,
      'Do you eat protein with every meal?', [
    AnswerOption('Rarely', 0),
    AnswerOption('Sometimes', 2),
    AnswerOption('Usually', 3),
    AnswerOption('Always — I track it', 4),
  ]),
  Question('nut_sugar', Pillar.nutrition,
      'How often do you have sugary drinks, sweets or desserts?', [
    AnswerOption('Multiple times a day', 0),
    AnswerOption('Daily', 1),
    AnswerOption('A few times a week', 2),
    AnswerOption('Once a week', 3),
    AnswerOption('Rarely or never', 4),
  ]),

  // Supplementation
  Question('sup_stack', Pillar.supplementation,
      'Do you take supplements consistently?', [
    AnswerOption('No', 0),
    AnswerOption('Sometimes, no real plan', 1),
    AnswerOption('A basic daily routine', 2),
    AnswerOption('A consistent, intentional stack', 4),
  ]),
  Question('sup_basis', Pillar.supplementation,
      'Is your supplement stack based on your bloodwork?', [
    AnswerOption('I don’t take supplements', 0),
    AnswerOption('No, it’s guesswork', 1),
    AnswerOption('Partly', 2),
    AnswerOption('Yes, guided by my labs', 4),
  ]),
  Question('sup_basics', Pillar.supplementation,
      'Do you cover the foundations — vitamin D, omega-3, magnesium, creatine?', [
    AnswerOption('None of them', 0),
    AnswerOption('One', 1),
    AnswerOption('Two', 2),
    AnswerOption('Three', 3),
    AnswerOption('All four', 4),
  ]),

  // Exercise
  Question('ex_strength', Pillar.exercise,
      'How often do you do resistance / strength training?', _freq),
  Question('ex_cardio', Pillar.exercise,
      'How often do you do 30+ minutes of cardio or brisk walking?', _freq),
  Question('ex_future', Pillar.exercise,
      'Could you lift a full suitcase into an overhead bin and run for a bus today?', [
    AnswerOption('Neither', 0),
    AnswerOption('One, with difficulty', 1),
    AnswerOption('Both, with difficulty', 2),
    AnswerOption('Both, comfortably', 4),
  ]),

  // Longevity Routines
  Question('rt_sleep', Pillar.routines, 'How many hours do you sleep on a typical night?', [
    AnswerOption('Less than 5', 0),
    AnswerOption('5–6', 1),
    AnswerOption('6–7', 2),
    AnswerOption('7–8', 4),
    AnswerOption('More than 9', 2),
  ]),
  Question('rt_light', Pillar.routines,
      'How often do you get morning sunlight within an hour of waking?', _freq),
  Question('rt_recovery', Pillar.routines,
      'How often do you use sauna, cold plunge, red light or hyperbaric?', _freq),
];

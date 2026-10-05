import 'package:flutter/material.dart';

/// The 8 dimensions of the REWIND Longevity Score.
enum Pillar {
  biomarkers,
  toxins,
  mindset,
  community,
  nutrition,
  supplementation,
  exercise,
  routines;

  static Pillar? fromKey(String key) {
    for (final p in Pillar.values) {
      if (p.name == key) return p;
    }
    return null;
  }

  String get label => switch (this) {
        Pillar.biomarkers => 'Blood Biomarkers',
        Pillar.toxins => 'Toxins',
        Pillar.mindset => 'Mindset',
        Pillar.community => 'Community',
        Pillar.nutrition => 'Nutrition',
        Pillar.supplementation => 'Supplementation',
        Pillar.exercise => 'Exercise',
        Pillar.routines => 'Longevity Routines',
      };

  String get short => switch (this) {
        Pillar.biomarkers => 'Biomarkers',
        Pillar.toxins => 'Toxins',
        Pillar.mindset => 'Mindset',
        Pillar.community => 'Community',
        Pillar.nutrition => 'Nutrition',
        Pillar.supplementation => 'Supplements',
        Pillar.exercise => 'Exercise',
        Pillar.routines => 'Routines',
      };

  String get description => switch (this) {
        Pillar.biomarkers =>
          'Your blood tells the truest story. Lipids, metabolic health, inflammation, hormones and more.',
        Pillar.toxins =>
          'What you are exposed to — personal products, your home and your environment.',
        Pillar.mindset =>
          'Stress, breathwork, meditation and the mental habits that shape how you age.',
        Pillar.community =>
          'Connection is medicine. Time with friends, family and the people who matter.',
        Pillar.nutrition =>
          'A way of eating built around your blood and your goals.',
        Pillar.supplementation =>
          'A targeted stack to move the numbers that matter for you.',
        Pillar.exercise =>
          'Strength, cardio and the movements you want to still do at 90.',
        Pillar.routines =>
          'Sleep, light, heat, cold and recovery — the daily rituals of longevity.',
      };

  IconData get icon => switch (this) {
        Pillar.biomarkers => Icons.bloodtype_outlined,
        Pillar.toxins => Icons.eco_outlined,
        Pillar.mindset => Icons.self_improvement,
        Pillar.community => Icons.people_alt_outlined,
        Pillar.nutrition => Icons.restaurant_outlined,
        Pillar.supplementation => Icons.medication_outlined,
        Pillar.exercise => Icons.fitness_center,
        Pillar.routines => Icons.nightlight_outlined,
      };

  /// Contribution of each pillar to the overall Longevity Score (sums to 1).
  double get weight => switch (this) {
        Pillar.biomarkers => 0.18,
        Pillar.toxins => 0.10,
        Pillar.mindset => 0.12,
        Pillar.community => 0.10,
        Pillar.nutrition => 0.14,
        Pillar.supplementation => 0.08,
        Pillar.exercise => 0.16,
        Pillar.routines => 0.12,
      };
}

/// Score band copy for a 0–100 value.
String scoreBand(int score) {
  if (score >= 85) return 'Exceptional';
  if (score >= 70) return 'Strong';
  if (score >= 55) return 'Building';
  if (score >= 40) return 'Needs focus';
  return 'Starting point';
}

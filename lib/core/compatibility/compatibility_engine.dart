class CompatibilityDimension {
  const CompatibilityDimension({
    required this.key,
    required this.weight,
    required this.userValue,
    required this.peerValue,
    required this.score,
    required this.isMatch,
    required this.summary,
  });

  final String key;
  final double weight;
  final String userValue;
  final String peerValue;
  final double score;
  final bool isMatch;
  final String summary;
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.percentage,
    required this.dimensions,
    required this.topMatchChips,
  });

  final double percentage;
  final List<CompatibilityDimension> dimensions;
  final List<String> topMatchChips;
}

class CompatibilityEngine {
  const CompatibilityEngine._();

  static CompatibilityResult calculate({
    required Map<String, String> user,
    required Map<String, String> peer,
  }) {
    final dimensions = <CompatibilityDimension>[];

    dimensions.add(_sleepSchedule(
      user['sleep_schedule'] ?? 'flexible',
      peer['sleep_schedule'] ?? 'flexible',
    ));
    dimensions.add(_cleanliness(
      user['cleanliness'] ?? 'tidy',
      peer['cleanliness'] ?? 'tidy',
    ));
    dimensions.add(_foodHabits(
      user['food_habits'] ?? 'no_preference',
      peer['food_habits'] ?? 'no_preference',
    ));
    dimensions.add(_smokingDrinking(
      user['smoking_drinking'] ?? 'neither',
      peer['smoking_drinking'] ?? 'neither',
    ));
    dimensions.add(_guestsPolicy(
      user['guests_policy'] ?? 'occasional_ok',
      peer['guests_policy'] ?? 'occasional_ok',
    ));
    dimensions.add(_workStyle(
      user['work_style'] ?? 'hybrid',
      peer['work_style'] ?? 'hybrid',
    ));

    double weightedSum = 0;
    double weightTotal = 0;
    for (final dim in dimensions) {
      weightedSum += dim.score * dim.weight;
      weightTotal += dim.weight;
    }

    final percentage = weightTotal > 0 ? (weightedSum / weightTotal) * 100.0 : 0.0;

    final topChips = <String>[];
    for (final dim in dimensions) {
      if (dim.isMatch && topChips.length < 3) {
        topChips.add(dim.summary);
      }
    }

    return CompatibilityResult(
      percentage: percentage.clamp(0, 100),
      dimensions: dimensions,
      topMatchChips: topChips,
    );
  }

  static CompatibilityDimension _sleepSchedule(String a, String b) {
    const values = ['early_bird', 'flexible', 'night_owl'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    double score;
    if (ai == bi) {
      score = 100;
    } else if ((ai - bi).abs() == 1) {
      score = 50;
    } else {
      score = 0;
    }
    return CompatibilityDimension(
      key: 'sleep_schedule',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same sleep schedule' : 'Similar sleep habits',
    );
  }

  static CompatibilityDimension _cleanliness(String a, String b) {
    const values = ['minimal', 'tidy', 'spotless'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    final gap = (ai - bi).abs();
    final score = switch (gap) { 0 => 100.0, 1 => 50.0, _ => 0.0 };
    return CompatibilityDimension(
      key: 'cleanliness',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: gap <= 1,
      summary: score == 100 ? 'Same cleanliness level' : 'Similar cleanliness',
    );
  }

  static CompatibilityDimension _foodHabits(String a, String b) {
    const strict = {'vegetarian', 'vegan'};
    double score;
    if (a == b) {
      score = 100;
    } else if (strict.contains(a) && !strict.contains(b)) {
      score = 0;
    } else if (!strict.contains(a) && !strict.contains(b)) {
      score = 100;
    } else {
      score = 30;
    }
    return CompatibilityDimension(
      key: 'food_habits',
      weight: 0.15,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same food habits' : 'Food preference gap',
    );
  }

  static CompatibilityDimension _smokingDrinking(String a, String b) {
    const nonSmoker = {'neither', 'drink_occasionally'};
    double score;
    if (a == b) {
      score = 100;
    } else if (nonSmoker.contains(a) && nonSmoker.contains(b)) {
      score = 80;
    } else if (nonSmoker.contains(a) && !nonSmoker.contains(b)) {
      score = 30;
    } else {
      score = 100;
    }
    return CompatibilityDimension(
      key: 'smoking_drinking',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score >= 50 ? 'Compatible habits' : 'Lifestyle gap',
    );
  }

  static CompatibilityDimension _guestsPolicy(String a, String b) {
    const values = ['no_overnight_guests', 'occasional_ok', 'open_house'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    final gap = (ai - bi).abs();
    final score = switch (gap) { 0 => 100.0, 1 => 60.0, _ => 20.0 };
    return CompatibilityDimension(
      key: 'guests_policy',
      weight: 0.15,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: gap <= 1,
      summary: score == 100 ? 'Same guest policy' : 'Similar guest policy',
    );
  }

  static CompatibilityDimension _workStyle(String a, String b) {
    double score;
    if (a == b) {
      score = 100;
    } else if ((a == 'wfh' && b == 'office') || (a == 'office' && b == 'wfh')) {
      score = 40;
    } else {
      score = 70;
    }
    return CompatibilityDimension(
      key: 'work_style',
      weight: 0.10,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same work style' : 'Different work styles',
    );
  }
}

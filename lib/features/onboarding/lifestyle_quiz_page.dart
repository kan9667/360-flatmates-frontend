import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class LifestyleQuizPage extends ConsumerStatefulWidget {
  const LifestyleQuizPage({required this.onComplete, super.key});

  final void Function(Map<String, String> answers) onComplete;

  @override
  ConsumerState<LifestyleQuizPage> createState() => _LifestyleQuizPageState();
}

class _LifestyleQuizPageState extends ConsumerState<LifestyleQuizPage> {
  final _answers = <String, String>{};
  late final List<_QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = [
      _QuizQuestion(
        key: 'sleep_schedule',
        emoji: '🌙',
        title: (l) => l.quizSleepSchedule,
        options: [
          _QuizOption(key: 'early_bird', label: (l) => l.quizEarlyBird),
          _QuizOption(key: 'flexible', label: (l) => l.quizFlexible),
          _QuizOption(key: 'night_owl', label: (l) => l.quizNightOwl),
        ],
      ),
      _QuizQuestion(
        key: 'cleanliness',
        emoji: '🧹',
        title: (l) => l.quizCleanliness,
        options: [
          _QuizOption(key: 'minimal', label: (l) => l.quizCleanMinimal),
          _QuizOption(key: 'tidy', label: (l) => l.quizCleanTidy),
          _QuizOption(key: 'spotless', label: (l) => l.quizCleanSpotless),
        ],
      ),
      _QuizQuestion(
        key: 'food_habits',
        emoji: '🍽️',
        title: (l) => l.quizFoodHabits,
        options: [
          _QuizOption(key: 'vegetarian', label: (l) => l.quizVegetarian),
          _QuizOption(key: 'vegan', label: (l) => l.quizVegan),
          _QuizOption(key: 'non_vegetarian', label: (l) => l.quizNonVegetarian),
          _QuizOption(key: 'no_preference', label: (l) => l.quizNoFoodPref),
        ],
      ),
      _QuizQuestion(
        key: 'smoking_drinking',
        emoji: '🚬',
        title: (l) => l.quizSmokingDrinking,
        options: [
          _QuizOption(key: 'neither', label: (l) => l.quizNeither),
          _QuizOption(key: 'smoke_outside', label: (l) => l.quizSmokeOutside),
          _QuizOption(key: 'drink_occasionally', label: (l) => l.quizDrinkOccasionally),
          _QuizOption(key: 'both_fine', label: (l) => l.quizBothFine),
        ],
      ),
      _QuizQuestion(
        key: 'guests_policy',
        emoji: '👥',
        title: (l) => l.quizGuestsPolicy,
        options: [
          _QuizOption(key: 'no_overnight_guests', label: (l) => l.quizNoGuests),
          _QuizOption(key: 'occasional_ok', label: (l) => l.quizOccasionalGuests),
          _QuizOption(key: 'open_house', label: (l) => l.quizOpenHouse),
        ],
      ),
      _QuizQuestion(
        key: 'parties_at_home',
        emoji: '🎉',
        title: (l) => l.quizParties,
        options: [
          _QuizOption(key: 'never', label: (l) => l.quizPartiesNever),
          _QuizOption(key: 'occasional_weekends', label: (l) => l.quizPartiesWeekends),
          _QuizOption(key: 'party_friendly', label: (l) => l.quizPartyFriendly),
        ],
      ),
      _QuizQuestion(
        key: 'work_style',
        emoji: '💻',
        title: (l) => l.quizWorkStyle,
        options: [
          _QuizOption(key: 'wfh', label: (l) => l.quizWfh),
          _QuizOption(key: 'office', label: (l) => l.quizOffice),
          _QuizOption(key: 'hybrid', label: (l) => l.quizHybrid),
        ],
      ),
      _QuizQuestion(
        key: 'pets',
        emoji: '🐾',
        title: (l) => l.quizPets,
        options: [
          _QuizOption(key: 'no_pets', label: (l) => l.quizNoPets),
          _QuizOption(key: 'have_pets', label: (l) => l.quizHavePets),
          _QuizOption(key: 'pet_friendly', label: (l) => l.quizPetFriendly),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final answeredCount = _answers.length;
    final totalQuestions = _questions.length;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    locale.quizProgress(answeredCount, totalQuestions),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: answeredCount / totalQuestions,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: _questions.map((q) {
                  final selected = _answers[q.key];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(q.emoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q.title(locale),
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: q.options.map((opt) {
                                final isSelected = selected == opt.key;
                                return ChoiceChip(
                                  key: Key('quiz_${q.key}_${opt.key}'),
                                  label: Text(opt.label(locale)),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _answers[q.key] = opt.key;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            GradientActionButton(
              key: const Key('onboarding_quiz_next'),
              label: locale.onboardingNext,
              onPressed: answeredCount == totalQuestions
                  ? () => widget.onComplete(Map.from(_answers))
                  : null,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.key,
    required this.emoji,
    required this.title,
    required this.options,
  });

  final String key;
  final String emoji;
  final String Function(AppLocalizations) title;
  final List<_QuizOption> options;
}

class _QuizOption {
  const _QuizOption({required this.key, required this.label});

  final String key;
  final String Function(AppLocalizations) label;
}

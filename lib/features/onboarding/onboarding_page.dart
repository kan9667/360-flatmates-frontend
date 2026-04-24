import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import 'budget_timeline_page.dart';
import 'lifestyle_quiz_page.dart';
import 'mode_selection_page.dart';
import 'non_negotiables_page.dart';
import 'onboarding_controller.dart';
import 'onboarding_splash_pages.dart';
import 'profile_photo_page.dart';
import 'basic_info_page.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final locale = AppLocalizations.of(context);

    if (state.isComplete) {
      Future.microtask(() => context.go('/discover'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.isSubmitting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(locale.onboardingSubmitting),
            ],
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => controller.submitNonNegotiables(state.nonNegotiables),
                child: Text(locale.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    return switch (state.step) {
      OnboardingStep.splash => OnboardingSplashPages(
          onComplete: () =>
              controller.setMode(state.mode ?? 'open_to_both'),
        ),
      OnboardingStep.modeSelection => ModeSelectionPage(
          onModeSelected: controller.setMode,
        ),
      OnboardingStep.basicInfo => BasicInfoPage(
          onNext: controller.setBasicInfo,
        ),
      OnboardingStep.profilePhoto => ProfilePhotoPage(
          onComplete: controller.setPhotoUrls,
        ),
      OnboardingStep.lifestyleQuiz => LifestyleQuizPage(
          onComplete: controller.setLifestyleAnswers,
        ),
      OnboardingStep.budgetTimeline => BudgetTimelinePage(
          onComplete: controller.setBudgetTimeline,
        ),
      OnboardingStep.nonNegotiables => NonNegotiablesPage(
          onComplete: controller.submitNonNegotiables,
        ),
    };
  }
}

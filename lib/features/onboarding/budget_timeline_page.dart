import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class BudgetTimelinePage extends ConsumerStatefulWidget {
  const BudgetTimelinePage({required this.onComplete, super.key});

  final void Function(Map<String, dynamic> data) onComplete;

  @override
  ConsumerState<BudgetTimelinePage> createState() => _BudgetTimelinePageState();
}

class _BudgetTimelinePageState extends ConsumerState<BudgetTimelinePage> {
  double _budgetMin = 5000;
  double _budgetMax = 25000;
  String _moveInTimeline = 'flexible';

  static const _timelineOptions = [
    _TimelineOption(key: 'immediate', icon: Icons.flash_on_rounded),
    _TimelineOption(key: 'this_month', icon: Icons.calendar_view_month_outlined),
    _TimelineOption(key: 'next_month', icon: Icons.event_outlined),
    _TimelineOption(key: 'flexible', icon: Icons.all_inclusive_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              locale.budgetTimelineTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.budgetTimelineSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.monthlyBudgetLabel,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_budgetMin.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '₹${_budgetMax.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      key: const Key('onboarding_budget_slider'),
                      values: RangeValues(_budgetMin, _budgetMax),
                      min: 5000,
                      max: 100000,
                      divisions: 19,
                      labels: RangeLabels(
                        '₹${_budgetMin.toStringAsFixed(0)}',
                        '₹${_budgetMax.toStringAsFixed(0)}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _budgetMin = values.start;
                          _budgetMax = values.end;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.moveInTimelineLabel,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _timelineOptions.map((opt) {
                        final selected = _moveInTimeline == opt.key;
                        return ChoiceChip(
                          key: Key('timeline_${opt.key}'),
                          avatar: Icon(opt.icon, size: 18),
                          label: Text(_timelineLabel(locale, opt.key)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _moveInTimeline = opt.key);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            GradientActionButton(
              key: const Key('onboarding_budget_next'),
              label: locale.onboardingNext,
              onPressed: () => widget.onComplete({
                'budget_min': _budgetMin,
                'budget_max': _budgetMax,
                'move_in_timeline': _moveInTimeline,
              }),
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _timelineLabel(AppLocalizations locale, String key) {
    switch (key) {
      case 'immediate':
        return locale.timelineImmediate;
      case 'this_month':
        return locale.timelineThisMonth;
      case 'next_month':
        return locale.timelineNextMonth;
      default:
        return locale.timelineFlexible;
    }
  }
}

class _TimelineOption {
  const _TimelineOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}

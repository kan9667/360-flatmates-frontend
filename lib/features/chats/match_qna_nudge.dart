import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class MatchQnANudge extends ConsumerStatefulWidget {
  const MatchQnANudge({
    required this.peerName,
    required this.onComplete,
    super.key,
  });

  final String peerName;
  final void Function(Map<String, String> answers) onComplete;

  @override
  ConsumerState<MatchQnANudge> createState() => _MatchQnANudgeState();
}

class _MatchQnANudgeState extends ConsumerState<MatchQnANudge> {
  final _q1Controller = TextEditingController();
  int _q2Value = 2; // 1-5 scale, default middle
  final _q3Controller = TextEditingController();

  static const _q2Labels = ['Very private', 'Private', 'Mixed', 'Social', 'Very social'];

  @override
  void dispose() {
    _q1Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.qnaNudgeTitle,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            locale.qnaNudgeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            locale.qnaQuestion1,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _q1Controller,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: locale.qnaQuestion1Hint,
              counterStyle: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.qnaQuestion2,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _q2Value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _q2Labels[_q2Value - 1],
            onChanged: (v) => setState(() => _q2Value = v.round()),
          ),
          const SizedBox(height: 16),
          Text(
            locale.qnaQuestion3,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _q3Controller,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: locale.qnaQuestion3Hint,
              counterStyle: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GradientActionButton(
                  label: locale.qnaAnswerCta,
                  onPressed: () {
                    widget.onComplete({
                      'q1': _q1Controller.text.trim(),
                      'q2': _q2Value.toString(),
                      'q3': _q3Controller.text.trim(),
                    });
                    Navigator.pop(context);
                  },
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.qnaSkipCta),
            ),
          ),
        ],
      ),
    );
  }
}

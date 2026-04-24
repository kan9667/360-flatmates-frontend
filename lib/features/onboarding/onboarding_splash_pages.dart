import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class OnboardingSplashPages extends ConsumerStatefulWidget {
  const OnboardingSplashPages({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingSplashPages> createState() => _OnboardingSplashPagesState();
}

class _OnboardingSplashPagesState extends ConsumerState<OnboardingSplashPages> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _SplashContent(
      emoji: '🏠',
      headline: 'Your perfect flat is out there.',
      assetIndex: 0,
    ),
    _SplashContent(
      emoji: '☕',
      headline: 'So is your perfect flatmate.',
      assetIndex: 1,
    ),
    _SplashContent(
      emoji: '✨',
      headline: '360 FlatMates finds both.',
      assetIndex: 2,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _page;
                  return Container(
                    width: active ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: isLast
                  ? GradientActionButton(
                      key: const Key('onboarding_get_started'),
                      label: locale.onboardingGetStarted,
                      onPressed: widget.onComplete,
                      icon: Icons.arrow_forward_rounded,
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('onboarding_next'),
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                        child: Text(locale.onboardingNext),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.emoji,
    required this.headline,
    required this.assetIndex,
  });

  final String emoji;
  final String headline;
  final int assetIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.18),
                  theme.colorScheme.primary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 28),
          ),
        ],
      ),
    );
  }
}

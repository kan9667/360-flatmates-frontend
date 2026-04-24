import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/compatibility/compatibility_ring.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'swipe_repository.dart';

class SwipeDeckPage extends ConsumerStatefulWidget {
  const SwipeDeckPage({super.key});

  @override
  ConsumerState<SwipeDeckPage> createState() => _SwipeDeckPageState();
}

class _SwipeDeckPageState extends ConsumerState<SwipeDeckPage> {
  int _currentIndex = 0;
  bool _isExpanded = false;
  bool _isAnimating = false;
  int _superLikesRemaining = 3;
  int _swipesToday = 0;
  static const _swipesPerDayCap = 100;
  final _swipeDebouncer = ActionDebouncer(duration: const Duration(milliseconds: 300));

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(swipeProfilesProvider);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return profiles.when(
      data: (items) {
        if (items.isEmpty) {
          return Scaffold(
            body: Center(child: Text(locale.emptySwipeDeck)),
          );
        }

        final userProfile = bootstrap.valueOrNull?.profile;
        final visible = items.where((i) => i.id != userProfile?.id).toList();

        if (visible.isEmpty || _currentIndex >= visible.length) {
          return Scaffold(
            body: Center(child: Text(locale.emptySwipeDeck)),
          );
        }

        final item = visible[_currentIndex];
        final compatibility = CompatibilityEngine.calculate(
          user: {
            'sleep_schedule': userProfile?.sleepSchedule ?? 'flexible',
            'cleanliness': userProfile?.cleanliness ?? 'tidy',
            'food_habits': userProfile?.foodHabits ?? 'no_preference',
            'smoking_drinking': userProfile?.smokingDrinking ?? 'neither',
            'guests_policy': userProfile?.guestsPolicy ?? 'occasional_ok',
            'work_style': userProfile?.workStyle ?? 'hybrid',
          },
          peer: {
            'sleep_schedule': item.sleepSchedule ?? 'flexible',
            'cleanliness': item.cleanliness ?? 'tidy',
            'food_habits': item.foodHabits ?? 'no_preference',
            'smoking_drinking': item.smokingDrinking ?? 'neither',
            'guests_policy': item.guestsPolicy ?? 'occasional_ok',
            'work_style': item.workStyle ?? 'hybrid',
          },
        );

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FlatmatesLogo(compact: true),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            locale.swipeCounterLabel(_swipesPerDayCap - _swipesToday),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale.superLikeCapLabel(_superLikesRemaining),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: _isExpanded
                        ? _ExpandedCard(
                            item: item,
                            compatibility: compatibility,
                          )
                        : _CollapsedCard(
                            item: item,
                            compatibility: compatibility,
                          ),
                  ),
                ),
                _ActionBar(
                  onPass: () => _swipeDebouncer.run(() => _handleAction('pass')),
                  onSuperLike: () => _swipeDebouncer.run(() => _handleAction('super_like')),
                  onLike: () => _swipeDebouncer.run(() => _handleAction('like')),
                  isAnimating: _isAnimating,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }

  Future<void> _handleAction(String action) async {
    if (_isAnimating) return;

    if (action == 'super_like' && _superLikesRemaining <= 0) {
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.superLikeCapLabel(0))),
      );
      return;
    }

    if (_swipesToday >= _swipesPerDayCap) {
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.swipeCounterLabel(0))),
      );
      return;
    }

    setState(() => _isAnimating = true);

    final profiles = ref.read(swipeProfilesProvider).valueOrNull ?? [];
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;
    final visible = profiles.where((i) => i.id != userProfile?.id).toList();

    if (_currentIndex >= visible.length) {
      setState(() => _isAnimating = false);
      return;
    }

    final item = visible[_currentIndex];

    try {
      await ref.read(swipeRepositoryProvider).swipeProfile(
            targetUserId: item.id,
            action: action,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _isAnimating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Action failed. Please try again.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _currentIndex++;
      _isExpanded = false;
      _isAnimating = false;
      _swipesToday++;
      if (action == 'super_like') _superLikesRemaining--;
    });

    ref.invalidate(swipeProfilesProvider);
  }
}

class _CollapsedCard extends StatelessWidget {
  const _CollapsedCard({
    required this.item,
    required this.compatibility,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: item.profileImageUrl != null
                          ? Image.network(
                              item.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _PhotoFallback(name: item.fullName),
                            )
                          : _PhotoFallback(name: item.fullName),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: InfoPill(
                        label: localizedFlatmatesModeLabel(locale, item.mode ?? 'open_to_both'),
                        highlighted: true,
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: CompatibilityRing(percentage: compatibility.percentage, size: 56),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.fullName ?? '', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              [item.locality, item.city].whereType<String>().join(', '),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        if (item.budgetMin != null || item.budgetMax != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: compatibility.topMatchChips.map((chip) {
                  return InfoPill(icon: Icons.check_circle_outline, label: chip);
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    locale.tapToSeeMore,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedCard extends StatelessWidget {
  const _ExpandedCard({
    required this.item,
    required this.compatibility,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                FlatmatesAvatar(name: item.fullName, imageUrl: item.profileImageUrl, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.fullName ?? '', style: theme.textTheme.headlineMedium),
                      InfoPill(
                        label: localizedFlatmatesModeLabel(locale, item.mode ?? 'open_to_both'),
                        highlighted: true,
                      ),
                    ],
                  ),
                ),
                CompatibilityRing(percentage: compatibility.percentage),
              ],
            ),
            const SizedBox(height: 20),
            Text(locale.aboutMeSection, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (item.bio != null && item.bio!.isNotEmpty)
              Text(item.bio!, style: theme.textTheme.bodyLarge)
            else
              Text(locale.noBioYet, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Text(locale.compatibilityBreakdown, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            CompatibilityBreakdown(result: compatibility),
            const SizedBox(height: 20),
            if (item.budgetMin != null || item.budgetMax != null) ...[
              Text(locale.budgetLabel, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              InfoPill(
                icon: Icons.currency_rupee_rounded,
                label: '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}/mo',
              ),
              const SizedBox(height: 20),
            ],
            if (item.moveInTimeline != null) ...[
              InfoPill(
                icon: Icons.event_outlined,
                label: localizedFlatmatesMoveInTimeline(locale, item.moveInTimeline!),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  locale.tapToCollapse,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.isAnimating,
  });

  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            key: const Key('swipe_pass'),
            icon: Icons.close_rounded,
            color: const Color(0xFFFF6B6B),
            size: 60,
            onPressed: isAnimating ? null : onPass,
          ),
          _ActionButton(
            key: const Key('swipe_super_like'),
            icon: Icons.star_rounded,
            color: Theme.of(context).colorScheme.tertiary,
            size: 50,
            onPressed: isAnimating ? null : onSuperLike,
          ),
          _ActionButton(
            key: const Key('swipe_like'),
            icon: Icons.favorite_rounded,
            color: const Color(0xFF10B981),
            size: 60,
            onPressed: isAnimating ? null : onLike,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(name),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 48,
          ),
        ),
      ),
    );
  }
}

String localizedFlatmatesMoveInTimeline(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'immediate':
      return locale.timelineImmediate;
    case 'this_month':
      return locale.timelineThisMonth;
    case 'next_month':
      return locale.timelineNextMonth;
    case 'flexible':
      return locale.timelineFlexible;
    default:
      return humanizeFlatmatesToken(value);
  }
}

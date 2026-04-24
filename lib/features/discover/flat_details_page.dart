import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/compatibility/compatibility_ring.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_ui.dart';
import '../swipe/swipe_repository.dart';
import 'discover_repository.dart';

class FlatDetailsPage extends ConsumerStatefulWidget {
  const FlatDetailsPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<FlatDetailsPage> createState() => _FlatDetailsPageState();
}

class _FlatDetailsPageState extends ConsumerState<FlatDetailsPage> {
  int _currentImageIndex = 0;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(discoverListingsProvider);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return listings.when(
      data: (items) {
        final listing = items.where((i) => i.id == widget.listingId).firstOrNull;
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(locale.emptyListings)),
          );
        }

        final userProfile = bootstrap.valueOrNull?.profile;
        final prefs = listing.preferences ?? {};
        final hasPeerData = prefs.containsKey('sleep_schedule');
        CompatibilityResult? compatibility;
        if (userProfile != null && hasPeerData) {
          compatibility = CompatibilityEngine.calculate(
            user: {
              'sleep_schedule': userProfile.sleepSchedule ?? 'flexible',
              'cleanliness': userProfile.cleanliness ?? 'tidy',
              'food_habits': userProfile.foodHabits ?? 'no_preference',
              'smoking_drinking': userProfile.smokingDrinking ?? 'neither',
              'guests_policy': userProfile.guestsPolicy ?? 'occasional_ok',
              'work_style': userProfile.workStyle ?? 'hybrid',
            },
            peer: {
              'sleep_schedule': prefs['sleep_schedule'] ?? 'flexible',
              'cleanliness': prefs['cleanliness'] ?? 'tidy',
              'food_habits': prefs['food_habits'] ?? 'no_preference',
              'smoking_drinking': prefs['smoking_drinking'] ?? 'neither',
              'guests_policy': prefs['guests_policy'] ?? 'occasional_ok',
              'work_style': prefs['work_style'] ?? 'hybrid',
            },
          );
        }

        final images = <String>[
          if (listing.mainImageUrl != null) listing.mainImageUrl!,
        ];

        return Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') {
                    _showReportDialog(context, locale);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'report',
                    child: Text(locale.reportListing),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _ImageCarousel(
                      images: images,
                      currentIndex: _currentImageIndex,
                      onPageChanged: (index) =>
                          setState(() => _currentImageIndex = index),
                      title: listing.title,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              if (listing.ownerName != null) ...[
                                Row(
                                  children: [
                                    FlatmatesAvatar(
                                      name: listing.ownerName,
                                      imageUrl: null,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      listing.ownerName!,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              InfoPill(
                                label: localizedFlatmatesModeLabel(
                                  locale,
                                  'room_poster',
                                ),
                                highlighted: true,
                              ),
                            ],
                          ),
                        ),
                        if (compatibility != null)
                          CompatibilityRing(
                            percentage: compatibility.percentage,
                            size: 64,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (listing.locality != null ||
                        listing.city != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              [
                                listing.locality,
                                listing.city,
                              ].whereType<String>().join(', '),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (listing.monthlyRent != null) ...[
                      Text(
                        locale.monthlyRentHeadline(
                          listing.monthlyRent!.toStringAsFixed(0),
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (compatibility != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: compatibility.topMatchChips
                            .map(
                              (chip) => InfoPill(
                                icon: Icons.check_circle_outline,
                                label: chip,
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    // About section
                    if (listing.description != null &&
                        listing.description!.trim().isNotEmpty) ...[
                      FlatmatesSectionHeader(
                        title: locale.aboutMe,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.description!,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Flat/Room details
                    FlatmatesSectionHeader(
                      title: locale.flatDetails,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (listing.sharingType != null)
                          InfoPill(
                            icon: Icons.bed_outlined,
                            label: localizedFlatmatesSharingTypeLabel(
                              locale,
                              listing.sharingType!,
                            ),
                          ),
                        if (listing.bedrooms != null)
                          InfoPill(
                            icon: Icons.king_bed_outlined,
                            label: locale.homeBedroomsChip(
                              listing.bedrooms!,
                            ),
                          ),
                        if (listing.bathrooms != null)
                          InfoPill(
                            icon: Icons.bathtub_outlined,
                            label: locale.homeBathsValue(
                              listing.bathrooms!,
                            ),
                          ),
                        if (listing.areaSqft != null)
                          InfoPill(
                            icon: Icons.square_foot_outlined,
                            label: locale.homeAreaValue(
                              listing.areaSqft!.toStringAsFixed(0),
                            ),
                          ),
                        if (listing.genderPreference != null)
                          InfoPill(
                            icon: Icons.person_outline,
                            label: localizedFlatmatesGenderLabel(
                              locale,
                              listing.genderPreference!,
                            ),
                          ),
                        ...listing.features.map(
                          (f) => InfoPill(
                            icon: Icons.check_circle_outline,
                            label: localizedFlatmatesFeatureLabel(locale, f),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Costs breakdown
                    if (listing.monthlyRent != null) ...[
                      FlatmatesSectionHeader(
                        title: locale.costsBreakdown,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _CostRow(
                                label: locale.monthlyRentInputLabel,
                                value:
                                    '₹${listing.monthlyRent!.toStringAsFixed(0)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Move-in date
                    if (listing.availableFrom != null) ...[
                      FlatmatesSectionHeader(
                        title: locale.moveInDate,
                      ),
                      const SizedBox(height: 8),
                      InfoPill(
                        icon: Icons.event_outlined,
                        label: DateFormat.yMMMd(locale.localeName)
                            .format(listing.availableFrom!),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              // Action bar
              _ActionBar(
                onPass: () => _handleAction('pass'),
                onSuperLike: () => _handleAction('super_like'),
                onLike: () => _handleAction('like'),
                isAnimating: _isAnimating,
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    if (action == 'pass') {
      if (mounted) {
        setState(() => _isAnimating = false);
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      if (action == 'super_like') {
        await ref.read(swipeRepositoryProvider).swipeProfile(
              targetUserId: widget.listingId,
              action: 'super_like',
            );
      }
      final conversationId = await ref
          .read(discoverRepositoryProvider)
          .likeListing(widget.listingId);
      if (mounted && conversationId != null) {
        context.push('/chats/$conversationId');
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
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
    }

    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }

  void _showReportDialog(BuildContext context, AppLocalizations locale) {
    final reasons = [
      locale.reportFakeProfile,
      locale.reportSpam,
      locale.reportInappropriate,
      locale.reportUncomfortable,
      locale.reportOther,
    ];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(locale.reportListing),
        children: reasons
            .map(
              (reason) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(locale.reportSubmitted)),
                  );
                },
                child: Text(reason),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    required this.title,
  });

  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (images.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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
            initialsFromName(title),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 48,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) => Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.9),
                        theme.colorScheme.primary.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initialsFromName(title),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: currentIndex == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
              alpha: 0.35,
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            key: const Key('flat_details_pass'),
            icon: Icons.close_rounded,
            color: const Color(0xFFFF6B6B),
            size: 60,
            onPressed: isAnimating ? null : onPass,
          ),
          _ActionButton(
            key: const Key('flat_details_super_like'),
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
            size: 50,
            onPressed: isAnimating ? null : onSuperLike,
          ),
          _ActionButton(
            key: const Key('flat_details_like'),
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
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}

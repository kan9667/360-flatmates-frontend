import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';

class ListingUnderReviewPage extends ConsumerWidget {
  const ListingUnderReviewPage({required this.listingId, super.key});

  final int listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(discoverListingsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(locale.listingUnderReviewTitle)),
      body: listings.when(
        data: (items) {
          final listing = items.where((i) => i.id == listingId).firstOrNull;
          final isRejected = listing?.isRejected ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // Status chip
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? theme.colorScheme.error.withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isRejected
                          ? theme.colorScheme.error.withValues(alpha: 0.3)
                          : theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRejected
                            ? Icons.error_outline
                            : Icons.hourglass_top_rounded,
                        size: 18,
                        color: isRejected
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRejected ? locale.listingRejected : locale.underReview,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isRejected
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Support text
              if (!isRejected)
                Center(
                  child: Text(
                    locale.reviewSupportText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Center(
                  child: Text(
                    'Your listing was not approved. Please review the reason below and resubmit.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 28),

              // What happens next
              if (!isRejected) ...[
                FlatmatesSectionHeader(
                  title: locale.whatHappensNext,
                ),
                const SizedBox(height: 16),
                _StepCard(
                  number: 1,
                  title: locale.aiPreScreen,
                  description:
                      'Our AI checks for policy compliance, image quality, and listing accuracy.',
                  icon: Icons.smart_toy_outlined,
                ),
                const SizedBox(height: 12),
                _StepCard(
                  number: 2,
                  title: locale.manualReview,
                  description:
                      'A member of our team verifies the details and may reach out if needed.',
                  icon: Icons.person_search_outlined,
                ),
                const SizedBox(height: 12),
                _StepCard(
                  number: 3,
                  title: locale.youWillBeNotified,
                  description:
                      locale.reviewStep3Desc,
                  icon: Icons.notifications_active_outlined,
                ),
                const SizedBox(height: 28),
              ],

              // Rejection reason
              if (isRejected) ...[
                Card(
                  color: theme.colorScheme.error.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rejection reason',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The listing did not meet our community guidelines. '
                          'Please ensure all information is accurate and photos are clear.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Preview card
              if (listing != null) ...[
                FlatmatesSectionHeader(
                  title: 'Your listing',
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        if (listing.mainImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              listing.mainImageUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.apartment_rounded),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.apartment_rounded),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (listing.monthlyRent != null)
                                Text(
                                  '₹${listing.monthlyRent!.toStringAsFixed(0)}/mo',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // CTAs
              if (isRejected)
                GradientActionButton(
                  label: locale.editResubmit,
                  onPressed: () => context.push('/post'),
                  icon: Icons.edit_outlined,
                )
              else ...[
                GradientActionButton(
                  label: locale.goToHomeFeed,
                  onPressed: () => context.go('/discover'),
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/flat-details/$listingId'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(locale.viewListing),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  final int number;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

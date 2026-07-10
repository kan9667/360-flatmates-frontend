import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../profile/profile_repository.dart';
import '../shared/presentation/components.dart';

final _waitlistNotifiedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final _waitlistSubmittingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class WaitlistPage extends ConsumerWidget {
  const WaitlistPage({required this.city, super.key});

  final String city;

  Future<void> _notify(BuildContext context, WidgetRef ref) async {
    final locale = AppLocalizations.of(context);
    ref.read(_waitlistSubmittingProvider.notifier).state = true;
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            payload: {
              'preferences': {
                'waitlist_city': city,
                'waitlist_at': DateTime.now().toUtc().toIso8601String(),
              },
            },
          );
      if (!context.mounted) return;
      ref.read(_waitlistNotifiedProvider.notifier).state = true;
      FlatmatesToast.success(context, locale.waitlistConfirmed);
    } catch (e, st) {
      debugPrint('[WaitlistPage] notify error: $e\n$st');
      if (!context.mounted) return;
      FlatmatesToast.error(context, locale.errorUnknown);
    } finally {
      ref.read(_waitlistSubmittingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final notified = ref.watch(_waitlistNotifiedProvider);
    final submitting = ref.watch(_waitlistSubmittingProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.horizontalScreen,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlatmatesEmptyState(
                icon: Icons.group_add_rounded,
                title: locale.waitlistTitle,
                subtitle: locale.waitlistSubtitle(city),
              ),
              const SizedBox(height: AppSpacing.screen),
              if (notified) ...[
                InfoPill(
                  icon: Icons.check_circle_rounded,
                  label: locale.waitlistConfirmed,
                  highlighted: true,
                ),
              ] else ...[
                FlatmatesButton(
                  label: locale.waitlistNotifyCta,
                  fullWidth: true,
                  onPressed: submitting ? null : () => _notify(context, ref),
                  icon: Icons.notifications_active_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                FlatmatesButton.secondary(
                  key: const Key('waitlist_invite_friends_button'),
                  label: locale.waitlistInviteFriends,
                  fullWidth: true,
                  onPressed: () {
                    final url = DeepLinkService.flatmatesUrl(city: city);
                    Share.share(locale.waitlistShareMessage(city, url));
                  },
                  icon: Icons.share_outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

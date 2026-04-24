import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class WaitlistPage extends ConsumerStatefulWidget {
  const WaitlistPage({required this.city, super.key});

  final String city;

  @override
  ConsumerState<WaitlistPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends ConsumerState<WaitlistPage> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        theme.colorScheme.primary.withValues(alpha: 0.06),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🏗️', style: TextStyle(fontSize: 52)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  locale.waitlistTitle,
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  locale.waitlistSubtitle(widget.city),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_notified)
                  InfoPill(
                    icon: Icons.check_circle_rounded,
                    label: locale.waitlistConfirmed,
                    highlighted: true,
                  )
                else
                  GradientActionButton(
                    label: locale.waitlistNotifyCta,
                    onPressed: () async {
                      try {
                        await ref.read(apiClientProvider).put(
                          '/flatmates/profile',
                          data: {'waitlist_city': widget.city},
                        );
                      } catch (_) {}
                      setState(() => _notified = true);
                    },
                    icon: Icons.notifications_active_outlined,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

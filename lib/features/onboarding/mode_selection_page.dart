import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';

class ModeSelectionPage extends ConsumerWidget {
  const ModeSelectionPage({required this.onModeSelected, super.key});

  final void Function(String mode) onModeSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              locale.modeSelectionTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.modeSelectionSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            _ModeCard(
              key: const Key('mode_room_poster'),
              emoji: '🏠',
              title: locale.modeRoomPoster,
              description: locale.modeRoomPosterDesc,
              onTap: () => onModeSelected('room_poster'),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              key: const Key('mode_co_hunter'),
              emoji: '🔍',
              title: locale.modeCoHunter,
              description: locale.modeCoHunterDesc,
              onTap: () => onModeSelected('co_hunter'),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              key: const Key('mode_open_to_both'),
              emoji: '✨',
              title: locale.modeOpenToBoth,
              description: locale.modeOpenToBothDesc,
              onTap: () => onModeSelected('open_to_both'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

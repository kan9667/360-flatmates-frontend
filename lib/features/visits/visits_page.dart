import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'visits_repository.dart';

class VisitsPage extends ConsumerStatefulWidget {
  const VisitsPage({super.key});

  @override
  ConsumerState<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends ConsumerState<VisitsPage> {
  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(visitsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: visits.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Text(locale.emptyVisits));
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(visitsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  FlatmatesSectionHeader(
                    title: locale.scheduleTitle,
                    subtitle: locale.scheduleSubtitle,
                  ),
                  const SizedBox(height: 18),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.55,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.event_available_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.propertyTitle,
                                          style: theme.textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'd MMM yyyy, h:mm a',
                                            locale.localeName,
                                          ).format(
                                            item.scheduledDate.toLocal(),
                                          ),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  InfoPill(
                                    label: localizedFlatmatesVisitStatusLabel(
                                      locale,
                                      item.status,
                                    ),
                                    highlighted:
                                        item.status == 'scheduled' ||
                                        item.status == 'confirmed',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  InfoPill(
                                    icon: Icons.meeting_room_outlined,
                                    label: item.visitContext == 'flatmate_meet'
                                        ? locale.flatmateMeetLabel
                                        : locale.propertyTourLabel,
                                  ),
                                  InfoPill(
                                    icon: Icons.calendar_month_outlined,
                                    label: DateFormat(
                                      'EEEE',
                                      locale.localeName,
                                    ).format(item.scheduledDate.toLocal()),
                                  ),
                                ],
                              ),
                              if (_hasActions(item.status)) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: _buildActions(item, locale, theme),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }

  bool _hasActions(String status) {
    return status == 'requested' ||
        status == 'scheduled' ||
        status == 'confirmed';
  }

  List<Widget> _buildActions(VisitItem item, AppLocalizations locale, ThemeData theme) {
    final actions = <Widget>[];

    if (item.status == 'requested') {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: () => _confirmVisit(item),
            child: Text(locale.visitConfirmTitle),
          ),
        ),
      );
      actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelVisit(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(locale.visitCancelCta),
          ),
        ),
      );
    } else if (item.status == 'scheduled' || item.status == 'confirmed') {
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rescheduleVisit(item),
            child: Text(locale.visitRescheduleCta),
          ),
        ),
      );
      actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelVisit(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(locale.visitCancelCta),
          ),
        ),
      );
    }

    return actions;
  }

  Future<void> _confirmVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);
    try {
      await ref.read(visitsRepositoryProvider).confirmVisit(item.id);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.visitConfirmed)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _cancelVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.visitCancelCta),
        content: Text(locale.visitCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.cancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(locale.visitCancelCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(visitsRepositoryProvider).cancelVisit(item.id);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.visitCancelled)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _rescheduleVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: item.scheduledDate.isAfter(DateTime.now())
          ? item.scheduledDate
          : DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.scheduledDate.toLocal()),
    );
    if (time == null || !mounted) return;

    final newDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await ref.read(visitsRepositoryProvider).rescheduleVisit(item.id, newDate);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.visitRescheduleCta)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

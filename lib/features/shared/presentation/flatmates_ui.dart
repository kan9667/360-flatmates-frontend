import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

String initialsFromName(String? name) {
  final raw = name?.trim();
  if (raw == null || raw.isEmpty) {
    return 'FM';
  }
  final parts = raw
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'FM';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(1, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class FlatmatesAvatar extends StatelessWidget {
  const FlatmatesAvatar({
    required this.name,
    super.key,
    this.imageUrl,
    this.size = 52,
  });

  final String? name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = initialsFromName(name);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.95),
            theme.colorScheme.primary.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _AvatarFallback(initials: initials, size: size),
              ),
            )
          : _AvatarFallback(initials: initials, size: size),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FlatmatesLogo extends StatelessWidget {
  const FlatmatesLogo({super.key, this.compact = false, this.centered = false});

  final bool compact;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberSize = compact ? 28.0 : 38.0;
    final labelSize = compact ? 13.0 : 15.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '36',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: numberSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  offset: Offset(0, compact ? -2 : -4),
                  child: Icon(
                    Icons.rotate_right_rounded,
                    color: theme.colorScheme.primary,
                    size: compact ? 30 : 38,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          'FLATMATES',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: labelSize,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: enabled
                ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.82),
                  ]
                : [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: enabled
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FlatmatesSectionHeader extends StatelessWidget {
  const FlatmatesSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({
    required this.label,
    super.key,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.colorScheme.surfaceContainerLowest;
    final foreground = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String localizedFlatmatesModeLabel(AppLocalizations locale, String mode) {
  switch (mode.trim().toLowerCase()) {
    case 'room_poster':
      return locale.modeRoomPoster;
    case 'seeker':
      return locale.modeSeeker;
    case 'co_hunter':
      return locale.modeCoHunter;
    case 'open_to_both':
      return locale.modeOpenToBoth;
    default:
      return humanizeFlatmatesToken(mode);
  }
}

String localizedFlatmatesGenderLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'any':
      return locale.genderAny;
    case 'male':
      return locale.genderMale;
    case 'female':
      return locale.genderFemale;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesSharingTypeLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'private_room':
      return locale.sharingPrivateRoom;
    case 'shared_room':
      return locale.sharingSharedRoom;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesVisitStatusLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'scheduled':
      return locale.visitStatusScheduled;
    case 'confirmed':
      return locale.visitStatusConfirmed;
    case 'completed':
      return locale.visitStatusCompleted;
    case 'cancelled':
    case 'canceled':
      return locale.visitStatusCancelled;
    case 'requested':
      return locale.visitStatusRequested;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesFeatureLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'furnished':
      return locale.featureFurnished;
    case 'semi_furnished':
      return locale.featureSemiFurnished;
    case 'wifi':
    case 'wi_fi':
    case 'wi-fi':
    case 'high_speed_wifi':
    case 'fast_wifi':
      return locale.featureWifi;
    case 'balcony':
      return locale.featureBalcony;
    case 'attached_bathroom':
      return locale.featureAttachedBathroom;
    case 'parking':
      return locale.featureParking;
    case 'ac':
    case 'air_conditioning':
      return locale.featureAc;
    case 'washing_machine':
      return locale.featureWashingMachine;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String humanizeFlatmatesToken(String value) {
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

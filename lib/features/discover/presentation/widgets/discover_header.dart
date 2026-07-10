import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/presentation/flatmates_ui.dart';

class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({
    required this.greeting,
    required this.location,
    required this.avatarUrl,
    required this.userName,
    this.onAvatarTap,
    this.onLocationTap,
    super.key,
  });

  final String greeting;
  final String location;
  final String? avatarUrl;
  final String? userName;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final primary = AppSemanticColors.textPrimaryFor(brightness);
    final secondary = AppSemanticColors.textSecondaryFor(brightness);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: primary,
                  fontSize: AppTypography.titleMdSize,
                  fontWeight: AppTypography.titleMdWeight,
                  height: AppTypography.titleMdHeight,
                  letterSpacing: AppTypography.titleMdLetterSpacing,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                _InteractivePressScale(
                  onTap: onLocationTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: secondary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondary,
                            fontWeight: AppTypography.captionWeight,
                            fontSize: AppTypography.captionSmSize,
                            height: AppTypography.captionSmHeight,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _InteractivePressScale(
          onTap: onAvatarTap,
          child: FlatmatesAvatar(name: userName, imageUrl: avatarUrl, size: 36),
        ),
      ],
    );
  }
}

/// Applies premium scale-down on press using Listener and AnimatedScale.
class _InteractivePressScale extends StatefulWidget {
  const _InteractivePressScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_InteractivePressScale> createState() => _InteractivePressScaleState();
}

class _InteractivePressScaleState extends State<_InteractivePressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: AppMotion.buttonPress,
          curve: AppMotion.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

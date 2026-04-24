import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../compatibility/compatibility_engine.dart';

class CompatibilityRing extends ConsumerWidget {
  const CompatibilityRing({
    required this.percentage,
    this.size = 72,
    this.strokeWidth = 5,
    super.key,
  });

  final double percentage;
  final double size;
  final double strokeWidth;

  Color _color(BuildContext context) {
    if (percentage >= 70) return const Color(0xFF10B981);
    if (percentage >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color(context);
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: strokeWidth,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${percentage.round()}%',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: size * 0.22,
            ),
          ),
        ],
      ),
    );
  }
}

class CompatibilityBreakdown extends StatelessWidget {
  const CompatibilityBreakdown({required this.result, super.key});

  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: result.dimensions.map((dim) {
        final icon = dim.isMatch ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
        final color = dim.isMatch ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dim.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/face_metrics.dart';
import '../theme/app_theme.dart';

class MetricsBottomSheet extends StatelessWidget {
  const MetricsBottomSheet({super.key, required this.metrics});

  final FaceMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 12),
      decoration: const BoxDecoration(
        color: AppTheme.panelColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Face Biometrics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _MetricBar(label: 'Eye Openness', value: metrics.averageEyeOpen),
          const SizedBox(height: 16),
          _MetricBar(label: 'Smile Probability', value: metrics.smileProbability),
          const SizedBox(height: 16),
          _MetricBar(label: 'Frown Score', value: metrics.frownScore, reversed: true),
          const SizedBox(height: 16),
          _MetricBar(label: 'Brow Raise Score', value: metrics.browRaiseScore, reversed: true),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    this.reversed = false,
  });

  final String label;
  final double value;
  final bool reversed;

  Color get _barColor {
    // If reversed, high value is bad. If not, high value is good.
    // E.g. Eyes Open: high=good. Frown: high=bad.
    final normalizedValue = reversed ? 1.0 - value : value;
    if (normalizedValue > 0.6) return AppTheme.happyColor;
    if (normalizedValue > 0.3) return AppTheme.tiredColor;
    return AppTheme.angryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(_barColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

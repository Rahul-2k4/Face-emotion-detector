import 'package:flutter/material.dart';

class PremiumSliderCard extends StatelessWidget {
  const PremiumSliderCard({
    super.key,
    required this.keyValue,
    required this.title,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String keyValue;
  final String title;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackShape: const RoundedRectSliderTrackShape(),
                trackHeight: 4.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              ),
              child: Slider(
                key: Key(keyValue),
                min: 0,
                max: max,
                value: value.clamp(0, max),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

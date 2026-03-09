import 'package:flutter/material.dart';
import '../models/conditions.dart';
import '../theme/app_theme.dart';

class PremiumResultCard extends StatelessWidget {
  const PremiumResultCard({super.key, required this.result});

  final ConditionResult result;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForEmotion(result.emotion);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelColor.withAlpha(220),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildEmotionIcon(result.emotion, color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _emotionLabel(result.emotion),
                      key: const Key('emotion_text'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.reason,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildConfidenceIndicator(result.confidence, color),
            ],
          ),
          const SizedBox(height: 20),
          _buildLightingPill(result.lighting),
        ],
      ),
    );
  }

  Widget _buildEmotionIcon(EmotionState emotion, Color color) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _emotionEmoji(emotion),
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence, Color color) {
    return SizedBox(
      height: 52,
      width: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: confidence,
            strokeWidth: 5,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '${(confidence * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightingPill(LightingState lighting) {
    final Color pillColor;
    final Color borderColor;
    final IconData icon;
    final String label;

    switch (lighting) {
      case LightingState.good:
        pillColor = const Color(0xFF4CAF50);
        borderColor = const Color(0xFF4CAF50);
        icon = Icons.wb_sunny_outlined;
        label = 'Optimal Lighting ✓';
        break;
      case LightingState.tooDim:
        pillColor = const Color(0xFF5C9EFF); // cold blue — "need more light"
        borderColor = const Color(0xFF5C9EFF);
        icon = Icons.brightness_3_outlined;
        label = 'Too Dim — needs more light';
        break;
      case LightingState.tooBright:
        pillColor = const Color(0xFFFF9800); // warm orange — "too much light"
        borderColor = const Color(0xFFFF9800);
        icon = Icons.wb_incandescent_outlined;
        label = 'Too Bright — reduce glare';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: pillColor.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha(90), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: pillColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: pillColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _emotionLabel(EmotionState state) {
    switch (state) {
      case EmotionState.tired: return 'Tired';
      case EmotionState.stressed: return 'Stressed';
      case EmotionState.happy: return 'Happy';
      case EmotionState.sad: return 'Sad';
      case EmotionState.neutral: return 'Neutral';
    }
  }

  String _emotionEmoji(EmotionState state) {
    switch (state) {
      case EmotionState.tired: return '😴';
      case EmotionState.stressed: return '😣';
      case EmotionState.happy: return '😊';
      case EmotionState.sad: return '😢';
      case EmotionState.neutral: return '😐';
    }
  }

}

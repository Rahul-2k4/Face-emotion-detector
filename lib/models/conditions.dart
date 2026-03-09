enum EmotionState { tired, stressed, happy, sad, neutral }

enum LightingState { tooDim, good, tooBright }

class ConditionResult {
  const ConditionResult({
    required this.emotion,
    required this.lighting,
    required this.confidence,
    required this.reason,
  });

  final EmotionState emotion;
  final LightingState lighting;
  final double confidence;
  final String reason;
}

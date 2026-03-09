import '../models/conditions.dart';
import '../models/emotion_probabilities.dart';
import '../models/face_metrics.dart';
import 'emotion_classifier.dart';
import 'lighting_analyzer.dart';

class ConditionDetector {
  const ConditionDetector({
    this.emotionClassifier = const EmotionClassifier(),
    this.lightingAnalyzer = const LightingAnalyzer(),
  });

  final EmotionClassifier emotionClassifier;
  final LightingAnalyzer lightingAnalyzer;

  ConditionResult detect(
    FaceMetrics metrics, {
    EmotionProbabilities probabilities = const EmotionProbabilities.neutral(),
  }) {
    final lighting = lightingAnalyzer.classify(metrics.lightingScore);
    final emotion = emotionClassifier.classify(
      metrics,
      probabilities: probabilities,
      lightingState: lighting,
    );
    final rawConfidence = emotionClassifier.confidence(
      metrics,
      emotion,
      probabilities,
    );
    final confidence =
        (rawConfidence - lightingAnalyzer.confidencePenalty(lighting)).clamp(
          0.0,
          1.0,
        );

    final reason = _dynamicReason(emotion, metrics, lighting, confidence);

    return ConditionResult(
      emotion: emotion,
      lighting: lighting,
      confidence: confidence,
      reason: reason,
    );
  }

  /// Build a context-aware explanation referencing the specific signals.
  String _dynamicReason(
    EmotionState emotion,
    FaceMetrics metrics,
    LightingState lighting,
    double confidence,
  ) {
    final eyePct = (metrics.averageEyeOpen * 100).round();
    final smilePct = (metrics.smileProbability * 100).round();
    final frownPct = (metrics.frownScore * 100).round();
    final browPct = (metrics.browRaiseScore * 100).round();

    String base;
    switch (emotion) {
      case EmotionState.tired:
        base = 'Eyes ${100 - eyePct}% drooped'
            '${metrics.headDownTiltDegrees > 5 ? ', head tilted ${metrics.headDownTiltDegrees.round()}°' : ''}'
            '${smilePct < 20 ? ', no smile' : ''}';
        break;
      case EmotionState.stressed:
        base = 'Brow raised $browPct%, eyes alert'
            '${frownPct > 20 ? ', frown $frownPct%' : ''}'
            '${smilePct < 15 ? ' — no smile' : ''}';
        break;
      case EmotionState.happy:
        base = 'Smile $smilePct% strong'
            '${eyePct > 65 ? ', eyes $eyePct% open' : ''}';
        break;
      case EmotionState.sad:
        base = 'Frown $frownPct% detected'
            '${smilePct < 15 ? ', no smile' : ''}'
            '${eyePct < 60 ? ', eyes $eyePct% open' : ''}';
        break;
      case EmotionState.neutral:
        base = 'No dominant expression detected';
        break;
    }

    // Append lighting note when compensation is active.
    String lightingNote = '';
    if (lighting == LightingState.tooDim) {
      lightingNote = ' (dim lighting — adjust for better accuracy)';
    } else if (lighting == LightingState.tooBright) {
      lightingNote = ' (bright lighting detected)';
    }

    return base + lightingNote;
  }
}

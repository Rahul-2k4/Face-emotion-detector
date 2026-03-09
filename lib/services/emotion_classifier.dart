import '../models/conditions.dart';
import '../models/emotion_probabilities.dart';
import '../models/face_metrics.dart';

class EmotionDebugInfo {
  const EmotionDebugInfo({
    required this.scores,
    required this.smileBand,
    required this.eyeBand,
    required this.directEmotion,
  });

  final Map<EmotionState, double> scores;
  final String smileBand;
  final String eyeBand;
  final EmotionState? directEmotion;
}

class EmotionClassifier {
  const EmotionClassifier();

  EmotionState classify(
    FaceMetrics metrics, {
    required EmotionProbabilities probabilities,
    required LightingState lightingState,
  }) {
    final directEmotion = _directEmotion(
      metrics,
      probabilities: probabilities,
      lightingState: lightingState,
    );
    if (directEmotion != null) {
      return directEmotion;
    }

    final scores = _scores(
      metrics,
      probabilities: probabilities,
      lightingState: lightingState,
    );

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first;
    final runnerUp = ranked.length > 1 ? ranked[1].value : 0.0;
    final thresholdBoost = lightingState == LightingState.good ? 0.0 : 0.05;
    final dimThresholdBoost = lightingState == LightingState.tooDim ? 0.08 : 0.0;

    if (best.key == EmotionState.neutral) {
      return EmotionState.neutral;
    }

    final heavySadPattern =
        best.key == EmotionState.sad &&
        metrics.averageEyeOpen <= 0.50 &&
        metrics.frownScore >= 0.22 &&
        metrics.smileProbability <= 0.10 &&
        metrics.browRaiseScore <= 0.18;
    if (heavySadPattern &&
        best.value >= 0.34 + thresholdBoost + dimThresholdBoost &&
        best.value - runnerUp >= 0.01) {
      return EmotionState.sad;
    }

    if (best.value < 0.32 + thresholdBoost + dimThresholdBoost ||
        best.value - runnerUp < (lightingState == LightingState.tooDim ? 0.04 : 0.02)) {
      return EmotionState.neutral;
    }

    return best.key;
  }

  double confidence(
    FaceMetrics metrics,
    EmotionState emotion,
    EmotionProbabilities probabilities,
  ) {
    final scores = _scores(
      metrics,
      probabilities: probabilities,
      lightingState: LightingState.good,
    );
    return _clamp01(scores[emotion] ?? 0.0);
  }

  EmotionDebugInfo debugInfo(
    FaceMetrics metrics, {
    required EmotionProbabilities probabilities,
    required LightingState lightingState,
  }) {
    final avgEye = metrics.averageEyeOpen;
    final smileBand = _smileBand(metrics.smileProbability);
    final eyeBand = _eyeBand(avgEye);
    return EmotionDebugInfo(
      scores: _scores(
        metrics,
        probabilities: probabilities,
        lightingState: lightingState,
      ),
      smileBand: smileBand.name,
      eyeBand: eyeBand.name,
      directEmotion: _directEmotion(
        metrics,
        probabilities: probabilities,
        lightingState: lightingState,
      ),
    );
  }

  Map<EmotionState, double> _scores(
    FaceMetrics metrics, {
    required EmotionProbabilities probabilities,
    required LightingState lightingState,
  }) {
    final ranked = probabilities.ranked(2);
    final topLabel = ranked.first.$1;
    final topScore = ranked.first.$2;
    final topMargin = ranked.length > 1 ? topScore - ranked[1].$2 : topScore;
    final happyScore = probabilities.happy > probabilities.surprised
        ? probabilities.happy
        : probabilities.surprised;
    final stressedBase = [
      probabilities.angry,
      probabilities.fearful,
      probabilities.disgusted,
    ].reduce((a, b) => a > b ? a : b);
    final avgEye = metrics.averageEyeOpen;
    final eyeClosed = (1.0 - avgEye).clamp(0.0, 1.0);
    final tiredSignal = eyeClosed;
    final normalizedTilt = (metrics.headDownTiltDegrees / 30.0).clamp(0.0, 1.0);
    final lowSmile = (1.0 - metrics.smileProbability).clamp(0.0, 1.0);
    final lowFrown = (1.0 - metrics.frownScore).clamp(0.0, 1.0);
    final lowExpression = (1.0 -
            [
              metrics.smileProbability,
              metrics.frownScore,
              metrics.browRaiseScore,
              eyeClosed * 0.8,
            ].reduce((a, b) => a > b ? a : b))
        .clamp(0.0, 1.0);
    final thresholdBoost = lightingState == LightingState.good ? 0.0 : 0.03;
    final smileBand = _smileBand(metrics.smileProbability);
    final eyeBand = _eyeBand(avgEye);
    final heavyEyes = eyeBand == _EyeBand.heavy;
    final alertEyes = eyeBand == _EyeBand.alert;
    final clearSmile = smileBand.index >= _SmileBand.clear.index;
    final strongSmile = smileBand == _SmileBand.strong;
    final sadModelLead =
        topLabel == BaseEmotionLabel.sad && topScore >= 0.38 && topMargin >= 0.08;

    final happy = _clamp01(
      (metrics.smileProbability * 0.62) +
          (happyScore * 0.28) +
          (avgEye * 0.06) +
          (lowFrown * 0.04),
    );

    final sad = _clamp01(
      (metrics.frownScore * 0.56) +
          (lowSmile * 0.18) +
          (probabilities.sad * 0.18) +
          (normalizedTilt * 0.08) -
          (metrics.smileProbability * 0.18),
    );

    final stressed = _clamp01(
      (metrics.browRaiseScore * 0.34) +
          (metrics.frownScore * 0.20) +
          (avgEye * 0.14) +
          (stressedBase * 0.18) +
          (lowSmile * 0.10) -
          (happyScore * 0.10),
    );

    final tired = _clamp01(
      (eyeClosed * 0.90) + (normalizedTilt * 0.10),
    );

    final neutral = _clamp01(
      (probabilities.neutral * 0.44) +
          (lowExpression * 0.28) +
          ((1.0 - eyeClosed) * 0.08) -
          (metrics.smileProbability * 0.10) -
          (metrics.frownScore * 0.08) -
          (metrics.browRaiseScore * 0.08),
    );

    final adjustedHappy =
        happy >= 0.50 ||
            clearSmile ||
            ((topLabel == BaseEmotionLabel.happy ||
                    topLabel == BaseEmotionLabel.surprised) &&
                topScore >= 0.30)
        ? happy +
            (strongSmile ? 0.10 : 0.06) +
            ((topLabel == BaseEmotionLabel.happy ||
                    topLabel == BaseEmotionLabel.surprised)
                ? (topMargin * 0.20) + (topScore * 0.10)
                : 0.0)
        : happy;
    final sadActivationThreshold =
        ((heavyEyes && metrics.browRaiseScore < 0.18) ? 0.30 : 0.36) +
        thresholdBoost;
    final adjustedSad =
        sad >= sadActivationThreshold &&
                metrics.frownScore >= 0.24 &&
                metrics.smileProbability <= 0.16
            ? sad +
                0.06 +
                (heavyEyes ? 0.08 : 0.0) +
                (metrics.browRaiseScore < 0.18 ? 0.08 : 0.0) +
                (normalizedTilt >= 0.18 ? 0.03 : 0.0)
            : sadModelLead &&
                    metrics.frownScore >= 0.14 &&
                    metrics.smileProbability <= 0.08 &&
                    metrics.browRaiseScore <= 0.18
                ? sad + 0.08 + (topMargin * 0.12)
                : sad * (clearSmile ? 0.54 : 0.82);
    final strongStressGeometry =
        metrics.browRaiseScore >= 0.30 || metrics.frownScore >= 0.18;
    final adjustedStressed = stressed >= 0.36 + thresholdBoost &&
            strongStressGeometry &&
            metrics.smileProbability <= 0.14
        ? stressed +
            0.05 +
            (alertEyes ? 0.06 : 0.0) -
            (heavyEyes ? 0.10 : 0.0) -
            (metrics.browRaiseScore < 0.20 ? 0.08 : 0.0)
        : stressed *
            (clearSmile
                ? 0.48
                : (!strongStressGeometry ? 0.70 : 0.84));
    final adjustedTired =
        tiredSignal >= (lightingState == LightingState.tooDim ? 0.62 : 0.55) &&
            metrics.frownScore < 0.26
        ? tired + 0.05
        : tired * 0.55;
    final adjustedNeutral = (clearSmile && adjustedHappy < 0.54
            ? neutral + 0.05
            : neutral) -
        ((heavyEyes &&
                metrics.frownScore >= 0.22 &&
                metrics.smileProbability <= 0.10)
            ? 0.08
            : 0.0);

    return <EmotionState, double>{
      EmotionState.happy: _clamp01(adjustedHappy),
      EmotionState.sad: _clamp01(adjustedSad),
      EmotionState.stressed: _clamp01(adjustedStressed),
      EmotionState.tired: _clamp01(adjustedTired),
      EmotionState.neutral: _clamp01(adjustedNeutral),
    };
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0);

  EmotionState? _directEmotion(
    FaceMetrics metrics, {
    required EmotionProbabilities probabilities,
    required LightingState lightingState,
  }) {
    final avgEye = metrics.averageEyeOpen;
    final normalizedTilt = (metrics.headDownTiltDegrees / 30.0).clamp(0.0, 1.0);
    final happyScore = probabilities.happy > probabilities.surprised
        ? probabilities.happy
        : probabilities.surprised;
    final stressedBase = [
      probabilities.angry,
      probabilities.fearful,
      probabilities.disgusted,
    ].reduce((a, b) => a > b ? a : b);
    final stressSignal =
        (metrics.browRaiseScore * 0.7) + (avgEye * 0.3);
    final tiredSignal = 1.0 - avgEye;
    final thresholdBoost = lightingState == LightingState.good ? 0.0 : 0.03;
    final dimThresholdBoost = lightingState == LightingState.tooDim ? 0.08 : 0.0;
    final eyeBand = _eyeBand(avgEye);
    final sadThreshold =
        ((eyeBand == _EyeBand.alert || metrics.browRaiseScore >= 0.28)
                ? 0.30
                : 0.22) +
        thresholdBoost +
        (lightingState == LightingState.tooDim ? 0.06 : 0.0);
    final sadDominance =
        metrics.frownScore >= 0.32 ||
        avgEye < 0.68 ||
        metrics.browRaiseScore < 0.26;
    final softSadModelLead =
        probabilities.sad >= (stressedBase + 0.10) &&
        probabilities.sad >= 0.28 &&
        metrics.frownScore >= 0.20 &&
        metrics.smileProbability < 0.10 &&
        metrics.browRaiseScore <= 0.34;

    final directHappy =
        metrics.smileProbability > (0.72 + thresholdBoost + (lightingState == LightingState.tooDim ? 0.03 : 0.0)) ||
        (metrics.smileProbability > 0.58 &&
            happyScore >= 0.18 &&
            metrics.frownScore < 0.18);
    if (directHappy) {
      return EmotionState.happy;
    }

    final directSad =
        metrics.frownScore >= sadThreshold &&
        metrics.smileProbability < 0.30 &&
        sadDominance;
    if (directSad) {
      return EmotionState.sad;
    }

    if (softSadModelLead) {
      return EmotionState.sad;
    }

    final directStressed =
        metrics.browRaiseScore >= 0.28 &&
        avgEye >= 0.72 &&
        stressSignal >= (0.62 + thresholdBoost + dimThresholdBoost) &&
        metrics.smileProbability < 0.25 &&
        metrics.frownScore < 0.30;
    if (directStressed) {
      return EmotionState.stressed;
    }

    final strongTired =
        tiredSignal > (lightingState == LightingState.tooDim ? 0.72 : 0.55) &&
        metrics.smileProbability < 0.30 &&
        metrics.frownScore < 0.30 &&
        normalizedTilt >= (lightingState == LightingState.tooDim ? 0.18 : 0.08);
    if (strongTired) {
      return EmotionState.tired;
    }

    return null;
  }

  _SmileBand _smileBand(double smileProbability) {
    if (smileProbability >= 0.62) {
      return _SmileBand.strong;
    }
    if (smileProbability >= 0.34) {
      return _SmileBand.clear;
    }
    return _SmileBand.weak;
  }

  _EyeBand _eyeBand(double averageEyeOpen) {
    if (averageEyeOpen >= 0.72) {
      return _EyeBand.alert;
    }
    if (averageEyeOpen <= 0.52) {
      return _EyeBand.heavy;
    }
    return _EyeBand.normal;
  }
}

enum _SmileBand { weak, clear, strong }

enum _EyeBand { heavy, normal, alert }

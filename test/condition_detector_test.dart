import 'package:face_condition_detection/models/conditions.dart';
import 'package:face_condition_detection/models/emotion_probabilities.dart';
import 'package:face_condition_detection/models/face_metrics.dart';
import 'package:face_condition_detection/services/condition_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detector = ConditionDetector();

  test('detects tired when eyes are closed and head is down', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.1,
      rightEyeOpenProbability: 0.16,
      smileProbability: 0.12,
      browTension: 0.4,
      frownScore: 0.12,
      browRaiseScore: 0.08,
      headDownTiltDegrees: 23,
      lightingScore: 0.5,
    );

    final result = detector.detect(
      metrics,
      probabilities: const EmotionProbabilities.neutral(),
    );
    expect(result.emotion, EmotionState.tired);
  });

  test('detects happy with strong smile and open eyes', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.72,
      rightEyeOpenProbability: 0.7,
      smileProbability: 0.82,
      browTension: 0.2,
      frownScore: 0.02,
      browRaiseScore: 0.06,
      headDownTiltDegrees: 5,
      lightingScore: 0.55,
    );

    final result = detector.detect(
      metrics,
      probabilities: const EmotionProbabilities(
        happy: 0.86,
        sad: 0.03,
        surprised: 0.04,
        fearful: 0.02,
        angry: 0.02,
        disgusted: 0.01,
        neutral: 0.02,
      ),
    );
    expect(result.emotion, EmotionState.happy);
    expect(result.lighting, LightingState.good);
  });

  test(
    'detects happy from strong smile even when model confidence is modest',
    () {
      const metrics = FaceMetrics(
        leftEyeOpenProbability: 0.74,
        rightEyeOpenProbability: 0.72,
        smileProbability: 0.83,
        browTension: 0.12,
        frownScore: 0.04,
        browRaiseScore: 0.10,
        headDownTiltDegrees: 4,
        lightingScore: 0.58,
      );

      const probabilities = EmotionProbabilities(
        happy: 0.33,
        sad: 0.28,
        surprised: 0.09,
        fearful: 0.06,
        angry: 0.05,
        disgusted: 0.03,
        neutral: 0.16,
      );

      final result = detector.detect(metrics, probabilities: probabilities);
      expect(result.emotion, EmotionState.happy);
    },
  );

  test('follows a clear happy model lead for the main heading', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.68,
      rightEyeOpenProbability: 0.70,
      smileProbability: 0.30,
      browTension: 0.14,
      frownScore: 0.05,
      browRaiseScore: 0.08,
      headDownTiltDegrees: 4,
      lightingScore: 0.56,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.52,
      sad: 0.18,
      surprised: 0.10,
      fearful: 0.05,
      angry: 0.04,
      disgusted: 0.03,
      neutral: 0.08,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.happy);
  });

  test('marks lighting as too dim and reduces confidence', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.45,
      rightEyeOpenProbability: 0.45,
      smileProbability: 0.4,
      browTension: 0.45,
      frownScore: 0.12,
      browRaiseScore: 0.10,
      headDownTiltDegrees: 8,
      lightingScore: 0.1,
    );

    final result = detector.detect(
      metrics,
      probabilities: const EmotionProbabilities.neutral(),
    );
    expect(result.lighting, LightingState.tooDim);
    expect(result.confidence, lessThan(0.8));
  });

  test('keeps low-smile neutral faces out of stressed', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.82,
      rightEyeOpenProbability: 0.8,
      smileProbability: 0.08,
      browTension: 0.16,
      frownScore: 0.06,
      browRaiseScore: 0.08,
      headDownTiltDegrees: 4,
      lightingScore: 0.58,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.05,
      sad: 0.08,
      surprised: 0.03,
      fearful: 0.04,
      angry: 0.06,
      disgusted: 0.02,
      neutral: 0.72,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.neutral);
  });

  test('does not mark sad without corroborating frown geometry', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.78,
      rightEyeOpenProbability: 0.8,
      smileProbability: 0.11,
      browTension: 0.12,
      frownScore: 0.08,
      browRaiseScore: 0.10,
      headDownTiltDegrees: 5,
      lightingScore: 0.55,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.05,
      sad: 0.79,
      surprised: 0.02,
      fearful: 0.02,
      angry: 0.03,
      disgusted: 0.01,
      neutral: 0.08,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.tired);
  });

  test('does not override a clear happy model lead into sad', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.70,
      rightEyeOpenProbability: 0.72,
      smileProbability: 0.32,
      browTension: 0.16,
      frownScore: 0.24,
      browRaiseScore: 0.12,
      headDownTiltDegrees: 5,
      lightingScore: 0.55,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.49,
      sad: 0.28,
      surprised: 0.07,
      fearful: 0.04,
      angry: 0.03,
      disgusted: 0.02,
      neutral: 0.07,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.happy);
  });

  test('detects sad from a strong frown pattern even when model is mixed', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.70,
      rightEyeOpenProbability: 0.72,
      smileProbability: 0.05,
      browTension: 0.34,
      frownScore: 0.42,
      browRaiseScore: 0.12,
      headDownTiltDegrees: 7,
      lightingScore: 0.57,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.08,
      sad: 0.31,
      surprised: 0.03,
      fearful: 0.08,
      angry: 0.09,
      disgusted: 0.05,
      neutral: 0.36,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.sad);
  });

  test('detects stressed from tense brow and alert eyes even without model lead', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.84,
      rightEyeOpenProbability: 0.82,
      smileProbability: 0.06,
      browTension: 0.52,
      frownScore: 0.24,
      browRaiseScore: 0.38,
      headDownTiltDegrees: 6,
      lightingScore: 0.54,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.05,
      sad: 0.11,
      surprised: 0.05,
      fearful: 0.12,
      angry: 0.14,
      disgusted: 0.05,
      neutral: 0.48,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.stressed);
  });

  test('prefers strong smile over a neutral leaning model', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.76,
      rightEyeOpenProbability: 0.78,
      smileProbability: 0.68,
      browTension: 0.10,
      frownScore: 0.04,
      browRaiseScore: 0.08,
      headDownTiltDegrees: 3,
      lightingScore: 0.56,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.21,
      sad: 0.07,
      surprised: 0.06,
      fearful: 0.04,
      angry: 0.03,
      disgusted: 0.02,
      neutral: 0.57,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.happy);
  });

  test('keeps a visible closed-mouth smile out of stressed', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.80,
      rightEyeOpenProbability: 0.78,
      smileProbability: 0.33,
      browTension: 0.40,
      frownScore: 0.20,
      browRaiseScore: 0.38,
      headDownTiltDegrees: 4,
      lightingScore: 0.56,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.07,
      sad: 0.10,
      surprised: 0.04,
      fearful: 0.16,
      angry: 0.19,
      disgusted: 0.05,
      neutral: 0.39,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, isNot(EmotionState.stressed));
    expect(result.emotion, EmotionState.neutral);
  });

  test('prefers sad over stressed for heavy-eyed frown faces', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.40,
      rightEyeOpenProbability: 0.42,
      smileProbability: 0.04,
      browTension: 0.28,
      frownScore: 0.33,
      browRaiseScore: 0.14,
      headDownTiltDegrees: 8,
      lightingScore: 0.55,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.03,
      sad: 0.16,
      surprised: 0.02,
      fearful: 0.12,
      angry: 0.14,
      disgusted: 0.05,
      neutral: 0.48,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.sad);
  });

  test('keeps stressed for alert eyes with raised brows', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.86,
      rightEyeOpenProbability: 0.84,
      smileProbability: 0.03,
      browTension: 0.46,
      frownScore: 0.22,
      browRaiseScore: 0.34,
      headDownTiltDegrees: 3,
      lightingScore: 0.55,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.03,
      sad: 0.10,
      surprised: 0.03,
      fearful: 0.17,
      angry: 0.18,
      disgusted: 0.04,
      neutral: 0.45,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.stressed);
  });

  test(
    'keeps neutral model-led faces out of stressed when brow raise is only moderate',
    () {
      const metrics = FaceMetrics(
        leftEyeOpenProbability: 0.78,
        rightEyeOpenProbability: 0.76,
        smileProbability: 0.08,
        browTension: 0.22,
        frownScore: 0.10,
        browRaiseScore: 0.38,
        headDownTiltDegrees: 4,
        lightingScore: 0.55,
      );

      const probabilities = EmotionProbabilities(
        happy: 0.03,
        sad: 0.08,
        surprised: 0.04,
        fearful: 0.07,
        angry: 0.09,
        disgusted: 0.03,
        neutral: 0.66,
      );

      final result = detector.detect(metrics, probabilities: probabilities);
      expect(result.emotion, EmotionState.neutral);
    },
  );

  test('prefers sad over stressed when frown is moderate and brow raise is not extreme', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.76,
      rightEyeOpenProbability: 0.74,
      smileProbability: 0.05,
      browTension: 0.26,
      frownScore: 0.22,
      browRaiseScore: 0.32,
      headDownTiltDegrees: 4,
      lightingScore: 0.55,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.03,
      sad: 0.32,
      surprised: 0.03,
      fearful: 0.12,
      angry: 0.14,
      disgusted: 0.03,
      neutral: 0.33,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.sad);
  });

  test('does not mark stressed when eyes are heavy and brow raise is weak', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.44,
      rightEyeOpenProbability: 0.46,
      smileProbability: 0.05,
      browTension: 0.24,
      frownScore: 0.24,
      browRaiseScore: 0.10,
      headDownTiltDegrees: 6,
      lightingScore: 0.55,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.03,
      sad: 0.12,
      surprised: 0.03,
      fearful: 0.15,
      angry: 0.16,
      disgusted: 0.05,
      neutral: 0.46,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, isNot(EmotionState.stressed));
    expect(result.emotion, EmotionState.sad);
  });

  test('keeps sad available with moderate frown and low-energy eyes', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.47,
      rightEyeOpenProbability: 0.49,
      smileProbability: 0.04,
      browTension: 0.22,
      frownScore: 0.22,
      browRaiseScore: 0.12,
      headDownTiltDegrees: 5,
      lightingScore: 0.56,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.04,
      sad: 0.18,
      surprised: 0.03,
      fearful: 0.11,
      angry: 0.12,
      disgusted: 0.04,
      neutral: 0.48,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.sad);
  });

  test('keeps a clear sad model lead from collapsing into tired', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.62,
      rightEyeOpenProbability: 0.64,
      smileProbability: 0.03,
      browTension: 0.18,
      frownScore: 0.17,
      browRaiseScore: 0.08,
      headDownTiltDegrees: 4,
      lightingScore: 0.56,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.05,
      sad: 0.47,
      surprised: 0.03,
      fearful: 0.09,
      angry: 0.08,
      disgusted: 0.04,
      neutral: 0.24,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.sad);
  });

  test('marks too bright lighting while preserving emotion detection', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.76,
      rightEyeOpenProbability: 0.78,
      smileProbability: 0.72,
      browTension: 0.10,
      frownScore: 0.04,
      browRaiseScore: 0.08,
      headDownTiltDegrees: 3,
      lightingScore: 0.93,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.28,
      sad: 0.05,
      surprised: 0.08,
      fearful: 0.03,
      angry: 0.03,
      disgusted: 0.02,
      neutral: 0.51,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.lighting, LightingState.tooBright);
    expect(result.emotion, EmotionState.happy);
  });

  test('prefers sad over stressed when frown crosses the sad threshold', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.76,
      rightEyeOpenProbability: 0.78,
      smileProbability: 0.06,
      browTension: 0.36,
      frownScore: 0.34,
      browRaiseScore: 0.32,
      headDownTiltDegrees: 4,
      lightingScore: 0.55,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.03,
      sad: 0.10,
      surprised: 0.03,
      fearful: 0.15,
      angry: 0.18,
      disgusted: 0.05,
      neutral: 0.46,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.emotion, EmotionState.sad);
  });

  test('uses neutral for dim ambiguous negative frames', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.58,
      rightEyeOpenProbability: 0.56,
      smileProbability: 0.08,
      browTension: 0.28,
      frownScore: 0.18,
      browRaiseScore: 0.18,
      headDownTiltDegrees: 6,
      lightingScore: 0.12,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.04,
      sad: 0.14,
      surprised: 0.02,
      fearful: 0.16,
      angry: 0.14,
      disgusted: 0.05,
      neutral: 0.45,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.lighting, LightingState.tooDim);
    expect(result.emotion, EmotionState.tired);
  });

  test('uses neutral for dim weak sad cues', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.48,
      rightEyeOpenProbability: 0.50,
      smileProbability: 0.05,
      browTension: 0.20,
      frownScore: 0.21,
      browRaiseScore: 0.12,
      headDownTiltDegrees: 5,
      lightingScore: 0.14,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.03,
      sad: 0.16,
      surprised: 0.03,
      fearful: 0.10,
      angry: 0.11,
      disgusted: 0.04,
      neutral: 0.53,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.lighting, LightingState.tooDim);
    expect(result.emotion, EmotionState.tired);
  });

  test('uses neutral for dim weak stressed cues', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.70,
      rightEyeOpenProbability: 0.68,
      smileProbability: 0.05,
      browTension: 0.24,
      frownScore: 0.14,
      browRaiseScore: 0.22,
      headDownTiltDegrees: 4,
      lightingScore: 0.13,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.03,
      sad: 0.07,
      surprised: 0.04,
      fearful: 0.18,
      angry: 0.16,
      disgusted: 0.05,
      neutral: 0.47,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.lighting, LightingState.tooDim);
    expect(result.emotion, EmotionState.neutral);
  });

  test('keeps strong happy visible in dim light', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.74,
      rightEyeOpenProbability: 0.72,
      smileProbability: 0.79,
      browTension: 0.10,
      frownScore: 0.04,
      browRaiseScore: 0.08,
      headDownTiltDegrees: 3,
      lightingScore: 0.15,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.26,
      sad: 0.05,
      surprised: 0.07,
      fearful: 0.03,
      angry: 0.03,
      disgusted: 0.02,
      neutral: 0.54,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.lighting, LightingState.tooDim);
    expect(result.emotion, EmotionState.happy);
  });

  test('keeps obvious tired visible in dim light', () {
    const metrics = FaceMetrics(
      leftEyeOpenProbability: 0.20,
      rightEyeOpenProbability: 0.22,
      smileProbability: 0.08,
      browTension: 0.16,
      frownScore: 0.08,
      browRaiseScore: 0.06,
      headDownTiltDegrees: 12,
      lightingScore: 0.14,
    );

    const probabilities = EmotionProbabilities(
      happy: 0.05,
      sad: 0.06,
      surprised: 0.03,
      fearful: 0.04,
      angry: 0.03,
      disgusted: 0.02,
      neutral: 0.77,
    );

    final result = detector.detect(metrics, probabilities: probabilities);
    expect(result.lighting, LightingState.tooDim);
    expect(result.emotion, EmotionState.tired);
  });
}

import 'package:face_condition_detection/models/face_metrics.dart';
import 'package:face_condition_detection/models/raw_face_signals.dart';
import 'package:face_condition_detection/services/frame_signal_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FrameSignalMapper();

  test('maps complete raw signals to bounded metrics', () {
    const raw = RawFaceSignals(
      leftEyeOpenProbability: 0.8,
      rightEyeOpenProbability: 0.75,
      smileProbability: 0.7,
      browTension: 0.6,
      frownScore: 0.2,
      browRaiseScore: 0.3,
      headEulerX: 12,
      lightingScore: 0.55,
    );

    final FaceMetrics metrics = mapper.map(raw);
    expect(metrics.leftEyeOpenProbability, closeTo(0.8, 0.0001));
    expect(metrics.rightEyeOpenProbability, closeTo(0.75, 0.0001));
    expect(metrics.smileProbability, closeTo(0.7, 0.0001));
    expect(metrics.browTension, closeTo(0.6, 0.0001));
    expect(metrics.frownScore, closeTo(0.2, 0.0001));
    expect(metrics.browRaiseScore, closeTo(0.3, 0.0001));
    expect(metrics.headDownTiltDegrees, closeTo(12, 0.0001));
    expect(metrics.lightingScore, closeTo(0.55, 0.0001));
  });

  test('uses safe defaults when nullable values are missing', () {
    const raw = RawFaceSignals(
      leftEyeOpenProbability: null,
      rightEyeOpenProbability: null,
      smileProbability: null,
      browTension: null,
      frownScore: null,
      browRaiseScore: null,
      headEulerX: null,
      lightingScore: null,
    );

    final FaceMetrics metrics = mapper.map(raw);
    expect(metrics.leftEyeOpenProbability, 0.5);
    expect(metrics.rightEyeOpenProbability, 0.5);
    expect(metrics.smileProbability, 0.5);
    expect(metrics.browTension, 0.35);
    expect(metrics.frownScore, 0);
    expect(metrics.browRaiseScore, 0);
    expect(metrics.headDownTiltDegrees, 0);
    expect(metrics.lightingScore, 0.5);
  });

  test('clamps out-of-range values into detector-safe range', () {
    const raw = RawFaceSignals(
      leftEyeOpenProbability: 5,
      rightEyeOpenProbability: -2,
      smileProbability: 2,
      browTension: -3,
      frownScore: 3,
      browRaiseScore: -1,
      headEulerX: 95,
      lightingScore: -6,
    );

    final FaceMetrics metrics = mapper.map(raw);
    expect(metrics.leftEyeOpenProbability, 1);
    expect(metrics.rightEyeOpenProbability, 0);
    expect(metrics.smileProbability, 1);
    expect(metrics.browTension, 0);
    expect(metrics.frownScore, 1);
    expect(metrics.browRaiseScore, 0);
    expect(metrics.headDownTiltDegrees, 35);
    expect(metrics.lightingScore, 0);
  });
}

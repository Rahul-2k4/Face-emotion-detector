import 'package:face_condition_detection/models/raw_face_signals.dart';
import 'package:face_condition_detection/services/lighting_compensator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compensator = LightingCompensator();

  test(
    'pulls extreme eye and smile probabilities toward midpoint in dim light',
    () {
      const raw = RawFaceSignals(
        leftEyeOpenProbability: 0.05,
        rightEyeOpenProbability: 0.1,
        smileProbability: 0.95,
        browTension: 0.8,
        frownScore: 0.3,
        browRaiseScore: 0.25,
        headEulerX: 0,
        lightingScore: 0.1,
      );

      final compensated = compensator.compensate(raw);

      expect(
        compensated.leftEyeOpenProbability!,
        greaterThan(raw.leftEyeOpenProbability!),
      );
      expect(
        compensated.rightEyeOpenProbability!,
        greaterThan(raw.rightEyeOpenProbability!),
      );
      expect(compensated.smileProbability!, lessThan(raw.smileProbability!));
      expect(compensated.browTension!, lessThan(raw.browTension!));
    },
  );

  test('applies only a mild correction in good lighting', () {
    const raw = RawFaceSignals(
      leftEyeOpenProbability: 0.4,
      rightEyeOpenProbability: 0.44,
      smileProbability: 0.58,
      browTension: 0.35,
      frownScore: 0.2,
      browRaiseScore: 0.18,
      headEulerX: 0,
      lightingScore: 0.55,
    );

    final compensated = compensator.compensate(raw);

    expect(
      (compensated.leftEyeOpenProbability! - raw.leftEyeOpenProbability!).abs(),
      lessThan(0.01),
    );
    expect(
      (compensated.smileProbability! - raw.smileProbability!).abs(),
      lessThan(0.01),
    );
  });

  test('brings over-bright probabilities closer to midpoint', () {
    const raw = RawFaceSignals(
      leftEyeOpenProbability: 0.95,
      rightEyeOpenProbability: 0.9,
      smileProbability: 0.9,
      browTension: 0.1,
      frownScore: 0.05,
      browRaiseScore: 0.12,
      headEulerX: 0,
      lightingScore: 0.97,
    );

    final compensated = compensator.compensate(raw);

    expect(
      compensated.leftEyeOpenProbability!,
      lessThan(raw.leftEyeOpenProbability!),
    );
    expect(
      compensated.rightEyeOpenProbability!,
      lessThan(raw.rightEyeOpenProbability!),
    );
    expect(compensated.smileProbability!, lessThan(raw.smileProbability!));
  });
}

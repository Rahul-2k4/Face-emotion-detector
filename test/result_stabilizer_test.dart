import 'package:face_condition_detection/models/conditions.dart';
import 'package:face_condition_detection/services/result_stabilizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ConditionResult result(
    EmotionState emotion, {
    double confidence = 0.7,
  }) {
    return ConditionResult(
      emotion: emotion,
      lighting: LightingState.good,
      confidence: confidence,
      reason: 'test',
    );
  }

  test('requires multiple stable frames before leaving neutral', () {
    final stabilizer = ResultStabilizer();

    final first = stabilizer.stabilize(result(EmotionState.stressed));
    final second = stabilizer.stabilize(result(EmotionState.stressed));
    final third = stabilizer.stabilize(result(EmotionState.stressed));

    expect(first.emotion, EmotionState.neutral);
    expect(second.emotion, EmotionState.stressed);
    expect(third.emotion, EmotionState.stressed);
  });

  test('bypasses streak for very high confidence frames', () {
    final stabilizer = ResultStabilizer();
    final first = stabilizer.stabilize(result(EmotionState.sad, confidence: 0.85));
    expect(first.emotion, EmotionState.sad);
  });

  test('holds happy briefly through a single neutral dip', () {
    final stabilizer = ResultStabilizer();

    stabilizer.stabilize(result(EmotionState.happy));
    stabilizer.stabilize(result(EmotionState.happy));
    final happy = stabilizer.stabilize(result(EmotionState.happy));
    final held = stabilizer.stabilize(result(EmotionState.neutral, confidence: 0.45));

    expect(happy.emotion, EmotionState.happy);
    expect(held.emotion, EmotionState.happy);
  });
}

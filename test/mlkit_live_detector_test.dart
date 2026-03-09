import 'package:camera/camera.dart';
import 'package:face_condition_detection/services/mlkit_live_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to high resolution for live camera analysis', () {
    final detector = MlkitLiveDetector();

    expect(detector.resolutionPreset, ResolutionPreset.high);
  });
}

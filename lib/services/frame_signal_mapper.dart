import '../models/face_metrics.dart';
import '../models/raw_face_signals.dart';

class FrameSignalMapper {
  const FrameSignalMapper();

  FaceMetrics map(RawFaceSignals raw) {
    return FaceMetrics(
      leftEyeOpenProbability: _clamp01(raw.leftEyeOpenProbability ?? 0.5),
      rightEyeOpenProbability: _clamp01(raw.rightEyeOpenProbability ?? 0.5),
      smileProbability: _clamp01(raw.smileProbability ?? 0.5),
      browTension: _clamp01(raw.browTension ?? 0.35),
      frownScore: _clamp01(raw.frownScore ?? 0.0),
      browRaiseScore: _clamp01(raw.browRaiseScore ?? 0.0),
      headDownTiltDegrees: _clamp(
        raw.headEulerX ?? 0.0,
        min: -35,
        max: 35,
      ).abs(),
      lightingScore: _clamp01(raw.lightingScore ?? 0.5),
    );
  }

  double _clamp01(double value) => _clamp(value, min: 0, max: 1);

  double _clamp(double value, {required double min, required double max}) {
    return value.clamp(min, max);
  }
}

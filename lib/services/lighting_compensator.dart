import '../models/raw_face_signals.dart';

/// Adjusts raw face signals to compensate for lighting conditions.
///
/// In dim lighting the camera increases noise and decreases contrast,
/// which causes facial features to appear less expressive. Rather than
/// suppressing signals (old behaviour), we preserve them more faithfully
/// and only moderately dampen noisy brow signals.
class LightingCompensator {
  const LightingCompensator({
    this.dimThreshold = 0.25,
    this.brightThreshold = 0.82,
  });

  final double dimThreshold;
  final double brightThreshold;

  RawFaceSignals compensate(RawFaceSignals raw) {
    final lighting = (raw.lightingScore ?? 0.5).clamp(0.0, 1.0).toDouble();
    final dimPressure = lighting < dimThreshold
        ? ((dimThreshold - lighting) / dimThreshold).clamp(0.0, 1.0)
        : 0.0;
    final brightPressure = lighting > brightThreshold
        ? ((lighting - brightThreshold) / (1.0 - brightThreshold)).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    // Bright pressure is now weighted less aggressively (0.50 vs 0.55).
    final pressure = (dimPressure * 0.60 + brightPressure * 0.50)
        .clamp(0.0, 1.0)
        .toDouble();

    // Stabilise smile/eye signals toward midpoint under pressure,
    // but with a smaller nudge than before (0.20 vs 0.30) so we keep
    // more of the real signal.
    double? stabilizeProbability(double? value) {
      if (value == null) return null;
      final towardMidpoint = 0.5 - value;
      return (value + (towardMidpoint * pressure * 0.20))
          .clamp(0.0, 1.0)
          .toDouble();
    }

    // Brow tension is still softened (bright light creates glare shadows).
    double? softenBrow(double? value) {
      if (value == null) return null;
      return (value * (1.0 - pressure * 0.20)).clamp(0.0, 1.0).toDouble();
    }

    // Frown & brow-raise in dim light: previously dampened 32 %, now only
    // 18 % so genuine negative expressions survive bad lighting.
    double? softenNegative(double? value) {
      if (value == null) return null;
      return (value * (1.0 - dimPressure * 0.18))
          .clamp(0.0, 1.0)
          .toDouble();
    }

    return raw.copyWith(
      leftEyeOpenProbability: stabilizeProbability(raw.leftEyeOpenProbability),
      rightEyeOpenProbability: stabilizeProbability(
        raw.rightEyeOpenProbability,
      ),
      smileProbability: stabilizeProbability(raw.smileProbability),
      browTension: softenBrow(raw.browTension),
      frownScore: softenNegative(raw.frownScore),
      browRaiseScore: softenNegative(raw.browRaiseScore),
    );
  }
}

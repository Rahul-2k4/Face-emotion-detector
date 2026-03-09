import '../models/conditions.dart';

class LightingAnalyzer {
  const LightingAnalyzer({
    this.dimThreshold = 0.25,
    this.brightThreshold = 0.82,
    // Moderate-dim zone: apply partial penalty instead of full penalty.
    this.moderateDimThreshold = 0.18,
  });

  final double dimThreshold;
  final double brightThreshold;
  final double moderateDimThreshold;

  LightingState classify(double lightingScore) {
    if (lightingScore < dimThreshold) {
      return LightingState.tooDim;
    }
    if (lightingScore > brightThreshold) {
      return LightingState.tooBright;
    }
    return LightingState.good;
  }

  /// Confidence penalty applied to detections made in bad lighting.
  /// Reduced penalties (was 0.18 dim / 0.12 bright) to trust the model more
  /// in difficult lighting instead of suppressing all non-neutral states.
  double confidencePenalty(LightingState state) {
    switch (state) {
      case LightingState.tooDim:
        return 0.10; // was 0.18
      case LightingState.tooBright:
        return 0.06; // was 0.12
      case LightingState.good:
        return 0.0;
    }
  }
}

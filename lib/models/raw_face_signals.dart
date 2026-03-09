class RawFaceSignals {
  const RawFaceSignals({
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.smileProbability,
    required this.browTension,
    required this.frownScore,
    required this.browRaiseScore,
    required this.headEulerX,
    required this.lightingScore,
  });

  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smileProbability;
  final double? browTension;
  final double? frownScore;
  final double? browRaiseScore;
  final double? headEulerX;
  final double? lightingScore;

  RawFaceSignals copyWith({
    double? leftEyeOpenProbability,
    double? rightEyeOpenProbability,
    double? smileProbability,
    double? browTension,
    double? frownScore,
    double? browRaiseScore,
    double? headEulerX,
    double? lightingScore,
  }) {
    return RawFaceSignals(
      leftEyeOpenProbability:
          leftEyeOpenProbability ?? this.leftEyeOpenProbability,
      rightEyeOpenProbability:
          rightEyeOpenProbability ?? this.rightEyeOpenProbability,
      smileProbability: smileProbability ?? this.smileProbability,
      browTension: browTension ?? this.browTension,
      frownScore: frownScore ?? this.frownScore,
      browRaiseScore: browRaiseScore ?? this.browRaiseScore,
      headEulerX: headEulerX ?? this.headEulerX,
      lightingScore: lightingScore ?? this.lightingScore,
    );
  }
}

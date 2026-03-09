class FaceMetrics {
  const FaceMetrics({
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.smileProbability,
    required this.browTension,
    required this.frownScore,
    required this.browRaiseScore,
    required this.headDownTiltDegrees,
    required this.lightingScore,
  });

  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final double smileProbability;
  final double browTension;
  final double frownScore;
  final double browRaiseScore;
  final double headDownTiltDegrees;
  final double lightingScore;

  double get averageEyeOpen =>
      (leftEyeOpenProbability + rightEyeOpenProbability) / 2.0;
}

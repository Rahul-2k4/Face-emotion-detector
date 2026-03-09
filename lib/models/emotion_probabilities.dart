enum BaseEmotionLabel {
  happy,
  sad,
  surprised,
  fearful,
  angry,
  disgusted,
  neutral,
}

class EmotionProbabilities {
  const EmotionProbabilities({
    required this.happy,
    required this.sad,
    required this.surprised,
    required this.fearful,
    required this.angry,
    required this.disgusted,
    required this.neutral,
  });

  const EmotionProbabilities.neutral()
    : happy = 0.03,
      sad = 0.03,
      surprised = 0.02,
      fearful = 0.02,
      angry = 0.02,
      disgusted = 0.02,
      neutral = 0.86;

  final double happy;
  final double sad;
  final double surprised;
  final double fearful;
  final double angry;
  final double disgusted;
  final double neutral;

  double scoreFor(BaseEmotionLabel label) {
    switch (label) {
      case BaseEmotionLabel.happy:
        return happy;
      case BaseEmotionLabel.sad:
        return sad;
      case BaseEmotionLabel.surprised:
        return surprised;
      case BaseEmotionLabel.fearful:
        return fearful;
      case BaseEmotionLabel.angry:
        return angry;
      case BaseEmotionLabel.disgusted:
        return disgusted;
      case BaseEmotionLabel.neutral:
        return neutral;
    }
  }

  BaseEmotionLabel get topLabel => ranked().first.$1;

  double get topScore => ranked().first.$2;

  List<(BaseEmotionLabel, double)> ranked([int limit = 7]) {
    final entries = <(BaseEmotionLabel, double)>[
      (BaseEmotionLabel.happy, happy),
      (BaseEmotionLabel.sad, sad),
      (BaseEmotionLabel.surprised, surprised),
      (BaseEmotionLabel.fearful, fearful),
      (BaseEmotionLabel.angry, angry),
      (BaseEmotionLabel.disgusted, disgusted),
      (BaseEmotionLabel.neutral, neutral),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return entries.take(limit).toList(growable: false);
  }

  EmotionProbabilities normalized() {
    final total =
        happy + sad + surprised + fearful + angry + disgusted + neutral;
    if (total <= 0) {
      return const EmotionProbabilities.neutral();
    }
    return EmotionProbabilities(
      happy: happy / total,
      sad: sad / total,
      surprised: surprised / total,
      fearful: fearful / total,
      angry: angry / total,
      disgusted: disgusted / total,
      neutral: neutral / total,
    );
  }

  EmotionProbabilities blend(
    EmotionProbabilities other, {
    required double alpha,
  }) {
    final clampedAlpha = alpha.clamp(0.0, 1.0);
    final beta = 1.0 - clampedAlpha;
    return EmotionProbabilities(
      happy: happy * beta + other.happy * clampedAlpha,
      sad: sad * beta + other.sad * clampedAlpha,
      surprised: surprised * beta + other.surprised * clampedAlpha,
      fearful: fearful * beta + other.fearful * clampedAlpha,
      angry: angry * beta + other.angry * clampedAlpha,
      disgusted: disgusted * beta + other.disgusted * clampedAlpha,
      neutral: neutral * beta + other.neutral * clampedAlpha,
    ).normalized();
  }

  String labelFor(BaseEmotionLabel label) {
    switch (label) {
      case BaseEmotionLabel.happy:
        return 'Happy';
      case BaseEmotionLabel.sad:
        return 'Sad';
      case BaseEmotionLabel.surprised:
        return 'Surprised';
      case BaseEmotionLabel.fearful:
        return 'Fearful';
      case BaseEmotionLabel.angry:
        return 'Angry';
      case BaseEmotionLabel.disgusted:
        return 'Disgusted';
      case BaseEmotionLabel.neutral:
        return 'Neutral';
    }
  }
}

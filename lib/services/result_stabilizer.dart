import '../models/conditions.dart';

/// Prevents flickering between emotion states by requiring consistent
/// evidence across frames before committing to a new emotion.
class ResultStabilizer {
  ConditionResult? _lastStableResult;
  EmotionState? _lastCandidateEmotion;
  int _emotionStreak = 0;
  int _happyHoldFrames = 0;

  ConditionResult stabilize(ConditionResult candidate) {
    if (_shouldHoldHappy(candidate)) {
      _happyHoldFrames -= 1;
      return _lastStableResult!;
    }

    // Neutral or very low confidence → show immediately (no streak needed).
    if (candidate.emotion == EmotionState.neutral ||
        candidate.confidence < 0.50) {
      _lastCandidateEmotion = null;
      _emotionStreak = 0;
      return _rememberStable(candidate);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // High-confidence bypass: if the model is very sure, skip streak check.
    // Threshold is lower for an emotion already shown (hysteresis).
    // ─────────────────────────────────────────────────────────────────────────
    final isCurrentEmotion = _lastStableResult?.emotion == candidate.emotion;
    final bypassThreshold = isCurrentEmotion
        ? 0.68  // easier to maintain a shown emotion
        : 0.78; // harder to establish a brand-new one instantly
    if (candidate.confidence >= bypassThreshold) {
      _lastCandidateEmotion = candidate.emotion;
      _emotionStreak = 3; // prime the streak so the next frame is also fast
      if (candidate.emotion == EmotionState.happy) _happyHoldFrames = 3;
      return _rememberStable(candidate);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Streak logic: require 2 consistent frames (was 3).
    // ─────────────────────────────────────────────────────────────────────────
    if (_lastCandidateEmotion == candidate.emotion) {
      _emotionStreak += 1;
    } else {
      _lastCandidateEmotion = candidate.emotion;
      _emotionStreak = 1;
    }

    // Required streak depends on confidence: more confident → fewer frames.
    final requiredStreak = candidate.confidence >= 0.65 ? 2 : 3;

    if (_emotionStreak >= requiredStreak) {
      if (candidate.emotion == EmotionState.happy) {
        _happyHoldFrames = 3; // extended hold (was 2)
      } else {
        _happyHoldFrames = 0;
      }
      return _rememberStable(candidate);
    }

    // Not enough frames yet — show neutral placeholder with reduced confidence.
    return ConditionResult(
      emotion: EmotionState.neutral,
      lighting: candidate.lighting,
      confidence: candidate.confidence * 0.5,
      reason: 'Gathering evidence across frames…',
    );
  }

  void reset() {
    _lastStableResult = null;
    _lastCandidateEmotion = null;
    _emotionStreak = 0;
    _happyHoldFrames = 0;
  }

  bool _shouldHoldHappy(ConditionResult candidate) {
    if (_lastStableResult?.emotion != EmotionState.happy ||
        _happyHoldFrames <= 0) {
      return false;
    }
    return candidate.emotion == EmotionState.neutral ||
        (candidate.emotion != EmotionState.tired &&
            candidate.emotion != EmotionState.happy &&
            candidate.confidence < 0.72);
  }

  ConditionResult _rememberStable(ConditionResult result) {
    _lastStableResult = result;
    return result;
  }
}

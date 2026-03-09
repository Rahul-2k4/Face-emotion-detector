# Face Condition Detection (Flutter)

This app is a take-home prototype for CCExtractor Flutter qualification work.

## Demo

- [Demo video (MP4)](demo/face_condition_demo.mp4)

## What it does

- Classifies user state as: `tired`, `stressed`, `happy`, `sad`, `neutral`
- Classifies lighting as: `too dim`, `good`, `too bright`
- Adapts signals for low-light and over-bright scenes to reduce false positives
- Adjusts emotion confidence based on lighting conditions
- Provides two modes:
  - `Live Camera`: real-time camera + ML Kit face signals
  - `Simulator`: slider-based deterministic validation mode

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
flutter test integration_test/app_flow_test.dart
```

Linux desktop integration test prerequisites:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y ninja-build libgtk-3-dev clang cmake pkg-config
```

If your environment exports a missing `clang++`, run:

```bash
unset CXX
unset CC
```

## Notes

- Core logic is implemented in:
  - `lib/services/condition_detector.dart`
  - `lib/services/emotion_classifier.dart`
  - `lib/services/lighting_analyzer.dart`
- Signal normalization is implemented in:
  - `lib/services/frame_signal_mapper.dart`
- Real-time detector is implemented in:
  - `lib/services/mlkit_live_detector.dart`
- Lighting compensation is implemented in:
  - `lib/services/lighting_compensator.dart`
- Camera permission/setup must be accepted on Android/iOS at runtime.

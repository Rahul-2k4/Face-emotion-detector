import 'dart:math' as math;
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/conditions.dart';
import '../models/emotion_probabilities.dart';
import '../models/face_metrics.dart';
import '../models/raw_face_signals.dart';
import 'condition_detector.dart';
import 'emotion_inference_service.dart';
import 'frame_signal_mapper.dart';
import 'lighting_compensator.dart';
import 'result_stabilizer.dart';

class MlkitLiveDetector {
  MlkitLiveDetector({
    ConditionDetector? conditionDetector,
    FrameSignalMapper? mapper,
    LightingCompensator? lightingCompensator,
    EmotionInferenceService? emotionInferenceService,
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
  }) : _detector = conditionDetector ?? const ConditionDetector(),
       _mapper = mapper ?? const FrameSignalMapper(),
       _lightingCompensator =
           lightingCompensator ?? const LightingCompensator(),
       _emotionInferenceService =
           emotionInferenceService ?? EmotionInferenceService(),
       _resolutionPreset = resolutionPreset;

  final ConditionDetector _detector;
  final FrameSignalMapper _mapper;
  final LightingCompensator _lightingCompensator;
  final EmotionInferenceService _emotionInferenceService;
  final ResolutionPreset _resolutionPreset;
  final ResultStabilizer _resultStabilizer = ResultStabilizer();
  final ValueNotifier<ConditionResult?> resultNotifier = ValueNotifier(null);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);
  final ValueNotifier<List<Rect>> boxesNotifier = ValueNotifier([]);
  final ValueNotifier<EmotionProbabilities?> probabilitiesNotifier =
      ValueNotifier(null);
  final ValueNotifier<FaceMetrics?> metricsNotifier = ValueNotifier(null);

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  bool _started = false;
  DateTime? _lastProcessedAt;
  double _emaLuma = 0.5;
  double _emaContrast = 0.2;
  double _emaSmile = 0.40;
  double _emaEyeLeft = 0.75;
  double _emaEyeRight = 0.75;
  double _emaFrown = 0.15;
  double _emaBrowRaise = 0.12;
  EmotionProbabilities _smoothedProbabilities =
      const EmotionProbabilities.neutral();
  // Faster EMA alpha = more responsive; was 0.30 (sluggish transitions)
  static const double _kEmaAlpha = 0.45;
  // Track last stable emotion for adaptive frame throttle
  EmotionState? _lastStableEmotion;
  bool _loggedFirstFrame = false;
  DateTime? _lastFaceDetectedAt;
  String? _cameraError;
  String? _modelWarning;

  CameraController? get cameraController => _cameraController;
  bool get isStarted => _started;
  ResolutionPreset get resolutionPreset => _resolutionPreset;
  bool get isFrontCamera =>
      _cameraController?.description.lensDirection == CameraLensDirection.front;

  Future<void> start({
    CameraLensDirection preferredDirection = CameraLensDirection.front,
  }) async {
    if (_started) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _cameraError = 'No camera available on this device.';
        _refreshErrorNotifier();
        return;
      }

      final CameraDescription camera = cameras.firstWhere(
        (c) => c.lensDirection == preferredDirection,
        orElse: () => cameras.first,
      );
      debugPrint(
        'MlkitLiveDetector.start: selected camera=${camera.name} lens=${camera.lensDirection}',
      );

      _cameraController = CameraController(
        camera,
        _resolutionPreset,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      debugPrint(
        'MlkitLiveDetector.start: initialized preview=${_cameraController!.value.previewSize}',
      );
      try {
        await _emotionInferenceService.load();
        _modelWarning = null;
      } catch (e) {
        debugPrint('MlkitLiveDetector.model load error: $e');
        _modelWarning =
            'Emotion model load failed. Falling back to neutral bias.';
        _refreshErrorNotifier();
      }

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableContours: true,
          enableTracking: true,
          minFaceSize: 0.10,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      await _cameraController!.startImageStream(_processFrame);
      _started = true;
      _cameraError = null;
      _refreshErrorNotifier();
      debugPrint('MlkitLiveDetector.start: image stream started');
    } catch (e) {
      _cameraError = 'Failed to start camera detector: $e';
      _refreshErrorNotifier();
      debugPrint('MlkitLiveDetector.start error: $e');
    }
  }

  Future<void> stop() async {
    _started = false;
    boxesNotifier.value = [];
    probabilitiesNotifier.value = null;
    metricsNotifier.value = null;
    _smoothedProbabilities = const EmotionProbabilities.neutral();
    _resultStabilizer.reset();
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    await _cameraController?.dispose();
    _cameraController = null;
    await _faceDetector?.close();
    _emotionInferenceService.dispose();
    _faceDetector = null;
    _isProcessing = false;
    _cameraError = null;
    _modelWarning = null;
    _refreshErrorNotifier();
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || _faceDetector == null || _cameraController == null) {
      return;
    }
    final now = DateTime.now();
    // Adaptive throttle: process faster when emotion state is changing.
    // 50ms (~20 FPS) during active change, 80ms (~12 FPS) when stable.
    final currentEmotion = resultNotifier.value?.emotion;
    final isChanging = currentEmotion != null && currentEmotion != _lastStableEmotion;
    final throttleMs = isChanging ? 50 : 80;
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < Duration(milliseconds: throttleMs)) {
      return;
    }
    _lastProcessedAt = now;
    _isProcessing = true;
    try {
      if (!_loggedFirstFrame) {
        _loggedFirstFrame = true;
        debugPrint(
          'MlkitLiveDetector.frame: size=${image.width}x${image.height} formatRaw=${image.format.raw} planes=${image.planes.length}',
        );
      }
      final inputImage = _toInputImage(image, _cameraController!.description);
      if (inputImage == null) {
        debugPrint(
          'MlkitLiveDetector.frame: InputImage conversion returned null',
        );
        return;
      }
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        boxesNotifier.value = [];
        if (_lastFaceDetectedAt != null &&
            now.difference(_lastFaceDetectedAt!) > const Duration(seconds: 2)) {
          resultNotifier.value = null;
          probabilitiesNotifier.value = null;
          metricsNotifier.value = null;
          _smoothedProbabilities = const EmotionProbabilities.neutral();
          _resultStabilizer.reset();
        }
        return;
      }
      _lastFaceDetectedAt = now;
      boxesNotifier.value = faces.map((f) => f.boundingBox).toList();
      final face = faces.first;
      final bool frontalFace = (face.headEulerAngleY ?? 0).abs() <= 18;
      final lighting = _estimateLighting(image.planes.first.bytes);
      final liveFrown = _extractFrownScore(face);
      final liveBrowRaise = _extractBrowRaiseScore(face);

      // Update EMA only for frontal frames with valid ML Kit values
      if (frontalFace) {
        if (face.leftEyeOpenProbability != null) {
          _emaEyeLeft =
              _emaEyeLeft * (1 - _kEmaAlpha) +
              face.leftEyeOpenProbability! * _kEmaAlpha;
        }
        if (face.rightEyeOpenProbability != null) {
          _emaEyeRight =
              _emaEyeRight * (1 - _kEmaAlpha) +
              face.rightEyeOpenProbability! * _kEmaAlpha;
        }
        if (face.smilingProbability != null) {
          _emaSmile =
              _emaSmile * (1 - _kEmaAlpha) +
              face.smilingProbability! * _kEmaAlpha;
        }
        _emaFrown = _emaFrown * (1 - _kEmaAlpha) + liveFrown * _kEmaAlpha;
        _emaBrowRaise =
            _emaBrowRaise * (1 - _kEmaAlpha) + liveBrowRaise * _kEmaAlpha;
      }

      final leftEyeOpen = frontalFace ? _emaEyeLeft : null;
      final rightEyeOpen = frontalFace ? _emaEyeRight : null;
      final smileProbability = frontalFace ? _emaSmile : null;
      final avgEye = (_emaEyeLeft + _emaEyeRight) / 2.0;
      final smile = _emaSmile;
      final derivedBrowTension = ((1 - avgEye) * 0.45 + (1 - smile) * 0.55)
          .clamp(0.0, 1.0);

      final raw = RawFaceSignals(
        leftEyeOpenProbability: leftEyeOpen,
        rightEyeOpenProbability: rightEyeOpen,
        smileProbability: smileProbability,
        browTension: derivedBrowTension,
        frownScore: frontalFace ? _emaFrown : liveFrown,
        browRaiseScore: frontalFace ? _emaBrowRaise : liveBrowRaise,
        headEulerX: face.headEulerAngleX,
        lightingScore: lighting,
      );

      final compensatedRaw = _lightingCompensator.compensate(raw);
      final metrics = _mapper.map(compensatedRaw);
      metricsNotifier.value = metrics;

      EmotionProbabilities probabilities = const EmotionProbabilities.neutral();
      try {
        if (_emotionInferenceService.isReady) {
          probabilities = await _emotionInferenceService.infer(
            image: image,
            boundingBox: face.boundingBox,
            rotationDegrees: _cameraController!.description.sensorOrientation,
          );
        }
      } catch (e) {
        debugPrint('MlkitLiveDetector.infer error: $e');
      }

      // Higher blend alpha = new model reading weighs more heavily → faster response.
      _smoothedProbabilities = _smoothedProbabilities.blend(
        probabilities,
        alpha: 0.50,
      );
      probabilitiesNotifier.value = _smoothedProbabilities;

      final candidateResult = _detector.detect(
        metrics,
        probabilities: _smoothedProbabilities,
      );
      final stableResult = _resultStabilizer.stabilize(candidateResult);
      resultNotifier.value = stableResult;
      _lastStableEmotion = stableResult.emotion;
      _cameraError = null;
      _refreshErrorNotifier();
    } catch (e) {
      _cameraError = 'Frame processing error: $e';
      _refreshErrorNotifier();
      debugPrint('MlkitLiveDetector.frame error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _refreshErrorNotifier() {
    final messages = [_cameraError, _modelWarning]
        .whereType<String>()
        .where((message) => message.trim().isNotEmpty)
        .toList(growable: false);
    errorNotifier.value = messages.isEmpty ? null : messages.join('\n');
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription description) {
    final rotation = InputImageRotationValue.fromRawValue(
      description.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final Uint8List bytes;
    final int bytesPerRow;

    if (Platform.isAndroid) {
      // Android NV21: Camera2 delivers planes with row-stride padding
      // (bytesPerRow >= width). Naively concatenating planes produces a
      // malformed NV21 buffer. Strip padding row-by-row.
      bytes = _buildCompactNv21(image);
      bytesPerRow = image.width;
    } else {
      // iOS BGRA8888: single plane, pass bytes directly.
      bytes = image.planes[0].bytes;
      bytesPerRow = image.planes[0].bytesPerRow;
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: bytesPerRow,
    );
    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _buildCompactNv21(CameraImage image) {
    // Some OEM devices (e.g. Samsung) deliver NV21 as a single pre-packed
    // plane. Return it directly — no stride stripping needed.
    if (image.planes.length == 1) {
      return image.planes[0].bytes;
    }

    final yPlane = image.planes[0];
    final uvPlane = image.planes[1];

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uvPlane.bytesPerRow;
    final int width = image.width;
    final int height = image.height;
    final int uvHeight = (height + 1) ~/ 2;

    final nv21 = Uint8List(width * height + width * uvHeight);

    int dstOffset = 0;
    for (int row = 0; row < height; row++) {
      nv21.setRange(
        dstOffset,
        dstOffset + width,
        yPlane.bytes,
        row * yRowStride,
      );
      dstOffset += width;
    }
    for (int row = 0; row < uvHeight; row++) {
      nv21.setRange(
        dstOffset,
        dstOffset + width,
        uvPlane.bytes,
        row * uvRowStride,
      );
      dstOffset += width;
    }
    return nv21;
  }

  double _estimateLighting(Uint8List bytes) {
    if (bytes.isEmpty) return 0.5;
    final int sampleSize = bytes.length < 2500 ? 1 : bytes.length ~/ 2500;
    final baselineLuma = _emaLuma;
    final baselineContrast = _emaContrast;
    int sampled = 0;
    double sum = 0.0;
    double sumSquares = 0.0;
    for (int i = 0; i < bytes.length; i += sampleSize) {
      final y = bytes[i].toDouble() / 255.0;
      sum += y;
      sumSquares += y * y;
      sampled++;
    }
    if (sampled == 0) return 0.5;
    final meanLuma = sum / sampled;
    final variance = math.max(
      0.0,
      (sumSquares / sampled) - (meanLuma * meanLuma),
    );
    final contrast = math.sqrt(variance);

    final contrastRatio = (contrast / (baselineContrast + 0.02))
        .clamp(0.5, 1.5)
        .toDouble();
    final contrastAwareLuma = (meanLuma * contrastRatio).clamp(0.0, 1.0);
    // Use raw meanLuma as the dominant factor (60 %) rather than adaptiveMean,
    // which self-normalises against _emaLuma and hides genuine dim conditions.
    final rawScore = (meanLuma * 0.60 + contrastAwareLuma * 0.40)
        .clamp(0.0, 1.0)
        .toDouble();

    // Update EMA faster (0.25 vs 0.12) so lighting changes register sooner.
    _emaLuma = (baselineLuma * 0.80) + (meanLuma * 0.20);
    _emaContrast = (baselineContrast * 0.85) + (contrast * 0.15);
    return rawScore;
  }

  double _extractFrownScore(Face face) {
    final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom];
    final noseBottom = face.contours[FaceContourType.noseBottom];
    final faceContour = face.contours[FaceContourType.face];
    if (lowerLipBottom == null ||
        noseBottom == null ||
        faceContour == null ||
        lowerLipBottom.points.isEmpty ||
        noseBottom.points.isEmpty ||
        faceContour.points.isEmpty) {
      return 0.0;
    }

    final lowerLipCenter =
        lowerLipBottom.points[lowerLipBottom.points.length ~/ 2];
    final noseCenter = noseBottom.points[noseBottom.points.length ~/ 2];
    final chinY = faceContour.points
        .map((point) => point.y.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final lipToNose = (lowerLipCenter.y - noseCenter.y).abs().toDouble();
    if (lipToNose < 1.0) {
      return 0.0;
    }
    final chinToLip = (chinY - lowerLipCenter.y).abs().toDouble();
    final score = ((chinToLip / lipToNose) - 0.95) * 1.9;
    return score.clamp(0.0, 1.0).toDouble();
  }

  double _extractBrowRaiseScore(Face face) {
    final leftBrow = face.contours[FaceContourType.leftEyebrowTop];
    final rightBrow = face.contours[FaceContourType.rightEyebrowTop];
    final leftEye = face.contours[FaceContourType.leftEye];
    final rightEye = face.contours[FaceContourType.rightEye];
    final noseBridge = face.contours[FaceContourType.noseBridge];
    if (leftBrow == null ||
        rightBrow == null ||
        leftEye == null ||
        rightEye == null ||
        noseBridge == null ||
        leftBrow.points.isEmpty ||
        rightBrow.points.isEmpty ||
        leftEye.points.isEmpty ||
        rightEye.points.isEmpty ||
        noseBridge.points.length < 2) {
      return 0.0;
    }

    final browY =
        (leftBrow.points[leftBrow.points.length ~/ 2].y +
            rightBrow.points[rightBrow.points.length ~/ 2].y) /
        2.0;
    final eyeY =
        (leftEye.points[leftEye.points.length ~/ 2].y +
            rightEye.points[rightEye.points.length ~/ 2].y) /
        2.0;
    final noseTop = noseBridge.points.first;
    final noseBottom = noseBridge.points.last;
    final noseLength = (noseBottom.y - noseTop.y).abs().toDouble();
    if (noseLength < 1.0) {
      return 0.0;
    }
    final normalizedDistance = (eyeY - browY) / noseLength;
    final score = (normalizedDistance - 0.36) * 2.2;
    return score.clamp(0.0, 1.0).toDouble();
  }
}

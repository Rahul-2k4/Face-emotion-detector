import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';

import '../models/emotion_probabilities.dart';

class EmotionInferenceService {
  EmotionInferenceService();

  Interpreter? _interpreter;
  List<String> _labels = const [];
  int _inputHeight = 48;
  int _inputWidth = 48;
  int _inputChannels = 1;
  int _outputSize = 7;

  // Cache last bounding box—if it moved <5% skip inference (saves ~15ms/frame)
  Rect? _lastBoundingBox;
  EmotionProbabilities? _lastInferredProbabilities;

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> load() async {
    if (isReady) {
      return;
    }

    // Use 4 threads – modern devices have 8 cores; was 2.
    final options = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset(
      'assets/models/emotion_model.tflite',
      options: options,
    );

    final rawLabels = await rootBundle.loadString(
      'assets/models/emotion_labels.txt',
    );
    _labels = rawLabels
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .map((label) => label.replaceFirst(RegExp(r'^\d+\s+'), ''))
        .toList(growable: false);

    final inputShape = _interpreter!.getInputTensor(0).shape;
    if (inputShape.length >= 4) {
      _inputHeight = inputShape[inputShape.length - 3];
      _inputWidth = inputShape[inputShape.length - 2];
      _inputChannels = inputShape[inputShape.length - 1];
    } else if (inputShape.length == 3) {
      _inputHeight = inputShape[0];
      _inputWidth = inputShape[1];
      _inputChannels = inputShape[2];
    }

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    _outputSize = outputShape.last;
  }

  Future<EmotionProbabilities> infer({
    required CameraImage image,
    required Rect boundingBox,
    required int rotationDegrees,
  }) async {
    if (!isReady) {
      return const EmotionProbabilities.neutral();
    }

    final uprightSize = _uprightSize(
      rawWidth: image.width.toDouble(),
      rawHeight: image.height.toDouble(),
      rotationDegrees: rotationDegrees,
    );
    final normalizedBox = _normalizedBox(
      boundingBox,
      uprightSize.width,
      uprightSize.height,
    );
    if (normalizedBox.width < 16 || normalizedBox.height < 16) {
      return const EmotionProbabilities.neutral();
    }

    // Skip inference if bounding box moved less than 5% of face size
    // (face is still) – reuse last result for that frame.
    if (_lastBoundingBox != null && _lastInferredProbabilities != null) {
      final dx = (normalizedBox.left - _lastBoundingBox!.left).abs();
      final dy = (normalizedBox.top - _lastBoundingBox!.top).abs();
      final movementThreshold = normalizedBox.width * 0.05;
      if (dx < movementThreshold && dy < movementThreshold) {
        return _lastInferredProbabilities!;
      }
    }
    _lastBoundingBox = normalizedBox;

    final input = _buildInputTensor(
      image,
      normalizedBox,
      rotationDegrees: rotationDegrees,
    );
    final output = [List<double>.filled(_outputSize, 0.0)];
    _interpreter!.run(input, output);

    final result = _scoresToProbabilities(output.first);
    _lastInferredProbabilities = result;
    return result;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _lastBoundingBox = null;
    _lastInferredProbabilities = null;
  }

  Rect _normalizedBox(Rect box, double width, double height) {
    final side = math.max(box.width, box.height) * 1.2;
    final centerX = box.left + box.width / 2.0;
    final centerY = box.top + box.height / 2.0;

    final clampedLeft = (centerX - side / 2.0).clamp(0.0, width - 1.0);
    final clampedTop = (centerY - side / 2.0).clamp(0.0, height - 1.0);
    final right = (clampedLeft + side).clamp(clampedLeft + 1.0, width);
    final bottom = (clampedTop + side).clamp(clampedTop + 1.0, height);
    return Rect.fromLTRB(clampedLeft, clampedTop, right, bottom);
  }

  Size _uprightSize({
    required double rawWidth,
    required double rawHeight,
    required int rotationDegrees,
  }) {
    switch (rotationDegrees % 180) {
      case 90:
        return Size(rawHeight, rawWidth);
      case 0:
      default:
        return Size(rawWidth, rawHeight);
    }
  }

  Offset _uprightPointToRaw(
    Offset point, {
    required double rawWidth,
    required double rawHeight,
    required int rotationDegrees,
  }) {
    switch (rotationDegrees % 360) {
      case 90:
        return Offset(point.dy, rawHeight - point.dx);
      case 180:
        return Offset(rawWidth - point.dx, rawHeight - point.dy);
      case 270:
        return Offset(rawWidth - point.dy, point.dx);
      case 0:
      default:
        return point;
    }
  }

  Object _buildInputTensor(
    CameraImage image,
    Rect uprightBox, {
    required int rotationDegrees,
  }) {
    if (_inputChannels <= 1) {
      return [
        List.generate(_inputHeight, (y) {
          return List.generate(_inputWidth, (x) {
            final gray = _sampleNormalizedGray(
              image,
              uprightBox,
              x,
              y,
              rotationDegrees: rotationDegrees,
            );
            return [gray];
          });
        }),
      ];
    }

    return [
      List.generate(_inputHeight, (y) {
        return List.generate(_inputWidth, (x) {
          final gray = _sampleNormalizedGray(
            image,
            uprightBox,
            x,
            y,
            rotationDegrees: rotationDegrees,
          );
          return List<double>.filled(_inputChannels, gray);
        });
      }),
    ];
  }

  double _sampleNormalizedGray(
    CameraImage image,
    Rect uprightBox,
    int x,
    int y, {
    required int rotationDegrees,
  }) {
    final uprightX =
        uprightBox.left + ((x + 0.5) / _inputWidth) * uprightBox.width;
    final uprightY =
        uprightBox.top + ((y + 0.5) / _inputHeight) * uprightBox.height;
    final rawPoint = _uprightPointToRaw(
      Offset(uprightX, uprightY),
      rawWidth: image.width.toDouble(),
      rawHeight: image.height.toDouble(),
      rotationDegrees: rotationDegrees,
    );
    final clampedX = rawPoint.dx.clamp(0.0, image.width - 1.0).toInt();
    final clampedY = rawPoint.dy.clamp(0.0, image.height - 1.0).toInt();

    final grayValue = _readGray(image, clampedX, clampedY);
    return (grayValue - 127.5) / 127.5;
  }

  double _readGray(CameraImage image, int x, int y) {
    final firstPlane = image.planes.first;

    if (image.planes.length > 1 || firstPlane.bytesPerPixel == 1) {
      final rowOffset = y * firstPlane.bytesPerRow;
      return firstPlane.bytes[rowOffset + x].toDouble();
    }

    final bytesPerPixel = firstPlane.bytesPerPixel ?? 4;
    final index = y * firstPlane.bytesPerRow + x * bytesPerPixel;
    final Uint8List bytes = firstPlane.bytes;
    final blue = bytes[index].toDouble();
    final green = bytes[index + 1].toDouble();
    final red = bytes[index + 2].toDouble();
    return (0.114 * blue) + (0.587 * green) + (0.299 * red);
  }

  EmotionProbabilities _scoresToProbabilities(List<double> rawScores) {
    final scores = rawScores.isEmpty
        ? List<double>.filled(_outputSize, 0.0)
        : rawScores;
    final rawSum = scores.fold<double>(0.0, (total, value) => total + value);
    final looksLikeProbabilities =
        scores.every((value) => value >= 0.0 && value <= 1.0) &&
        (rawSum - 1.0).abs() <= 0.15;

    final probabilities = looksLikeProbabilities
        ? scores
        : () {
            final maxScore = scores.reduce(math.max);
            final expScores = scores
                .map((score) => math.exp(score - maxScore))
                .toList();
            final sum = expScores.fold<double>(
              0.0,
              (total, value) => total + value,
            );
            return expScores
                .map((value) => sum == 0 ? 0.0 : value / sum)
                .toList(growable: false);
          }();

    double scoreForLabel(String label) {
      final index = _labels.indexWhere(
        (candidate) => candidate.toLowerCase() == label.toLowerCase(),
      );
      if (index < 0 || index >= probabilities.length) {
        return 0.0;
      }
      return probabilities[index];
    }

    return EmotionProbabilities(
      happy: scoreForLabel('Happy'),
      sad: scoreForLabel('Sad'),
      surprised: math.max(
        scoreForLabel('Surprised'),
        scoreForLabel('Surprise'),
      ),
      fearful: math.max(scoreForLabel('Fearful'), scoreForLabel('Fear')),
      angry: scoreForLabel('Angry'),
      disgusted: math.max(scoreForLabel('Disgusted'), scoreForLabel('Disgust')),
      neutral: scoreForLabel('Neutral'),
    ).normalized();
  }
}

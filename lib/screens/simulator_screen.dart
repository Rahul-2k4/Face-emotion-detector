import 'package:flutter/material.dart';

import '../models/emotion_probabilities.dart';
import '../models/face_metrics.dart';
import '../services/condition_detector.dart';
import '../widgets/metrics_bottom_sheet.dart';
import '../widgets/result_card.dart';
import '../widgets/slider_card.dart';
import '../theme/app_theme.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final ConditionDetector detector = const ConditionDetector();

  double leftEye = 0.6;
  double rightEye = 0.6;
  double smile = 0.5;
  double frownScore = 0.08;
  double browRaiseScore = 0.10;
  double headTilt = 8.0;
  double lighting = 0.55;
  BaseEmotionLabel simulatedLabel = BaseEmotionLabel.neutral;
  double modelConfidence = 0.82;

  @override
  Widget build(BuildContext context) {
    final metrics = FaceMetrics(
      leftEyeOpenProbability: leftEye,
      rightEyeOpenProbability: rightEye,
      smileProbability: smile,
      browTension: (frownScore + browRaiseScore) / 2.0,
      frownScore: frownScore,
      browRaiseScore: browRaiseScore,
      headDownTiltDegrees: headTilt,
      lightingScore: lighting,
    );
    final probabilities = _buildSimulatorProbabilities();
    final result = detector.detect(metrics, probabilities: probabilities);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          key: const Key('simulator_list'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GestureDetector(
                    onTap: () {
                       showModalBottomSheet(
                         context: context,
                         builder: (context) => MetricsBottomSheet(metrics: metrics),
                       );
                    },
                    child: PremiumResultCard(result: result),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Quick Presets',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _PresetChip(
                          key: const Key('preset_neutral'),
                          label: 'Neutral',
                          color: AppTheme.neutralColor,
                          onTap: () => _applyPreset('Neutral'),
                        ),
                        const SizedBox(width: 8),
                        _PresetChip(
                          key: const Key('preset_happy'),
                          label: 'Happy',
                          color: AppTheme.happyColor,
                          onTap: () => _applyPreset('Happy'),
                        ),
                        const SizedBox(width: 8),
                        _PresetChip(
                          key: const Key('preset_sad'),
                          label: 'Sad',
                          color: AppTheme.sadColor,
                          onTap: () => _applyPreset('Sad'),
                        ),
                        const SizedBox(width: 8),
                        _PresetChip(
                          key: const Key('preset_stressed'),
                          label: 'Stressed',
                          color: AppTheme.angryColor,
                          onTap: () => _applyPreset('Stressed'),
                        ),
                        const SizedBox(width: 8),
                        _PresetChip(
                          key: const Key('preset_tired'),
                          label: 'Tired',
                          color: AppTheme.tiredColor,
                          onTap: () => _applyPreset('Tired'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  const Text(
                    'Model Output',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.panelColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BaseEmotionLabel>(
                        key: const Key('model_label_dropdown'),
                        isExpanded: true,
                        dropdownColor: AppTheme.panelColor,
                        value: simulatedLabel,
                        items: BaseEmotionLabel.values
                            .map((label) {
                              return DropdownMenuItem<BaseEmotionLabel>(
                                value: label,
                                child: Text(_baseEmotionLabel(label)),
                              );
                            })
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => simulatedLabel = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PremiumSliderCard(
                    keyValue: 'model_confidence_slider',
                    title: 'Model Confidence',
                    value: modelConfidence,
                    max: 1.0,
                    onChanged: (v) => setState(() => modelConfidence = v),
                  ),

                  const SizedBox(height: 32),
                  
                  const Text(
                    'Face Signals',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  PremiumSliderCard(
                    keyValue: 'left_eye_slider',
                    title: 'Left Eye Openness',
                    value: leftEye,
                    max: 1.0,
                    onChanged: (v) => setState(() => leftEye = v),
                  ),
                  PremiumSliderCard(
                    keyValue: 'right_eye_slider',
                    title: 'Right Eye Openness',
                    value: rightEye,
                    max: 1.0,
                    onChanged: (v) => setState(() => rightEye = v),
                  ),
                  PremiumSliderCard(
                    keyValue: 'smile_slider',
                    title: 'Smile Probability',
                    value: smile,
                    max: 1.0,
                    onChanged: (v) => setState(() => smile = v),
                  ),
                  PremiumSliderCard(
                    keyValue: 'frown_slider',
                    title: 'Frown Score',
                    value: frownScore,
                    max: 1.0,
                    onChanged: (v) => setState(() => frownScore = v),
                  ),
                  PremiumSliderCard(
                    keyValue: 'brow_raise_slider',
                    title: 'Brow Raise Score',
                    value: browRaiseScore,
                    max: 1.0,
                    onChanged: (v) => setState(() => browRaiseScore = v),
                  ),
                  PremiumSliderCard(
                    keyValue: 'head_tilt_slider',
                    title: 'Head Down Tilt (deg)',
                    value: headTilt,
                    max: 35.0,
                    onChanged: (v) => setState(() => headTilt = v),
                  ),
                  PremiumSliderCard(
                    keyValue: 'lighting_slider',
                    title: 'Lighting Score',
                    value: lighting,
                    max: 1.0,
                    onChanged: (v) => setState(() => lighting = v),
                  ),
                  const SizedBox(height: 48), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  EmotionProbabilities _buildSimulatorProbabilities() {
    final remaining = (1.0 - modelConfidence).clamp(0.0, 1.0);
    final background = remaining / 6.0;
    double scoreFor(BaseEmotionLabel label) =>
        simulatedLabel == label ? modelConfidence : background;

    return EmotionProbabilities(
      happy: scoreFor(BaseEmotionLabel.happy),
      sad: scoreFor(BaseEmotionLabel.sad),
      surprised: scoreFor(BaseEmotionLabel.surprised),
      fearful: scoreFor(BaseEmotionLabel.fearful),
      angry: scoreFor(BaseEmotionLabel.angry),
      disgusted: scoreFor(BaseEmotionLabel.disgusted),
      neutral: scoreFor(BaseEmotionLabel.neutral),
    ).normalized();
  }

  void _applyPreset(String preset) {
    switch (preset) {
      case 'Neutral':
        setState(() {
          simulatedLabel = BaseEmotionLabel.neutral;
          modelConfidence = 0.86;
          smile = 0.18;
          leftEye = 0.72;
          rightEye = 0.70;
          frownScore = 0.08;
          browRaiseScore = 0.10;
          headTilt = 6;
          lighting = 0.55;
        });
        return;
      case 'Happy':
        setState(() {
          simulatedLabel = BaseEmotionLabel.happy;
          modelConfidence = 0.86;
          smile = 0.82;
          leftEye = 0.74;
          rightEye = 0.72;
          frownScore = 0.02;
          browRaiseScore = 0.08;
          headTilt = 4;
          lighting = 0.58;
        });
        return;
      case 'Sad':
        setState(() {
          simulatedLabel = BaseEmotionLabel.sad;
          modelConfidence = 0.74;
          smile = 0.12;
          leftEye = 0.52;
          rightEye = 0.50;
          frownScore = 0.48;
          browRaiseScore = 0.16;
          headTilt = 10;
          lighting = 0.55;
        });
        return;
      case 'Stressed':
        setState(() {
          simulatedLabel = BaseEmotionLabel.angry;
          modelConfidence = 0.78;
          smile = 0.10;
          leftEye = 0.78;
          rightEye = 0.76;
          frownScore = 0.34;
          browRaiseScore = 0.40;
          headTilt = 6;
          lighting = 0.55;
        });
        return;
      case 'Tired':
        setState(() {
          simulatedLabel = BaseEmotionLabel.neutral;
          modelConfidence = 0.66;
          smile = 0.10;
          leftEye = 0.24;
          rightEye = 0.26;
          frownScore = 0.12;
          browRaiseScore = 0.10;
          headTilt = 18;
          lighting = 0.50;
        });
        return;
    }
  }

  String _baseEmotionLabel(BaseEmotionLabel label) {
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

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(100)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/conditions.dart';
import '../models/face_metrics.dart';
import '../services/mlkit_live_detector.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_face_box.dart';
import '../widgets/camera_preview_viewport.dart';
import '../widgets/metrics_bottom_sheet.dart';
import '../widgets/result_card.dart';
import '../widgets/scanning_overlay.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> with WidgetsBindingObserver {
  late final MlkitLiveDetector liveDetector;
  bool _starting = true;
  bool _disposed = false;
  CameraLensDirection _direction = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    liveDetector = MlkitLiveDetector();
    _startDetector();
  }

  Future<void> _startDetector() async {
    if (_disposed) return;
    setState(() => _starting = true);
    await liveDetector.start(preferredDirection: _direction);
    if (mounted) {
      setState(() => _starting = false);
    }
  }

  Future<void> _restartDetector() async {
    await liveDetector.stop();
    if (!_disposed) {
      await _startDetector();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      liveDetector.stop();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _startDetector();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    liveDetector.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: liveDetector.errorNotifier,
      builder: (context, error, _) {
        final CameraController? camera = liveDetector.cameraController;
        final bool isCameraReady = camera != null && camera.value.isInitialized;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Preview
              if (isCameraReady)
                ColoredBox(
                  color: Colors.black,
                  child: CameraPreviewViewport(
                      aspectRatio: camera.value.aspectRatio == 0
                          ? (3 / 4)
                          : camera.value.aspectRatio,
                      child: CameraPreview(camera),
                  ),
                ),
                
              // 2. Animated UI Overlay over Camera
              if (isCameraReady)
                ValueListenableBuilder<ConditionResult?>(
                  valueListenable: liveDetector.resultNotifier,
                  builder: (context, result, _) {
                    return ValueListenableBuilder<List<Rect>>(
                      valueListenable: liveDetector.boxesNotifier,
                      builder: (context, boxes, _) {
                        if (boxes.isEmpty) {
                          return const ScanningOverlay();
                        }
                        
                        final color = result != null 
                            ? AppTheme.colorForEmotion(result.emotion)
                            : Colors.white;

                        return AnimatedFaceBox(
                          boxes: boxes,
                          previewSize: Size(
                            camera.value.previewSize!.height,
                            camera.value.previewSize!.width,
                          ),
                          isFrontCamera: liveDetector.isFrontCamera,
                          color: color,
                        );
                      }
                    );
                  }
                )
              else if (_starting)
                const ColoredBox(
                  color: AppTheme.surfaceColor,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                    ),
                  ),
                ),

              // 3. Error Messages
              if (error != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(220),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(error, style: const TextStyle(color: Colors.white)),
                  ),
                ),

              if (!isCameraReady && !_starting && error != null)
                Center(
                  child: ElevatedButton.icon(
                    key: const Key('retry_camera_button'),
                    onPressed: _restartDetector,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Camera'),
                  ),
                ),

              // 4. Floating Action Buttons (Camera Switch)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: AppTheme.panelColor.withAlpha(200),
                  child: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _direction = _direction == CameraLensDirection.front
                          ? CameraLensDirection.back
                          : CameraLensDirection.front;
                    });
                    _restartDetector();
                  },
                ),
              ),

              // 5. Result Card (Bottom)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: ValueListenableBuilder<ConditionResult?>(
                  valueListenable: liveDetector.resultNotifier,
                  builder: (context, result, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2), 
                          end: Offset.zero
                        ).animate(CurvedAnimation(
                          parent: animation, 
                          curve: Curves.easeOutBack,
                        )),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: result == null
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              onTap: () => _showMetricsBottomSheet(context),
                              child: PremiumResultCard(result: result),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMetricsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ValueListenableBuilder<FaceMetrics?>(
          valueListenable: liveDetector.metricsNotifier,
          builder: (context, metrics, _) {
            if (metrics == null) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            return MetricsBottomSheet(metrics: metrics);
          },
        );
      },
    );
  }
}

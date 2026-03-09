import 'package:flutter/material.dart';

class AnimatedFaceBox extends StatefulWidget {
  const AnimatedFaceBox({
    super.key,
    required this.boxes,
    required this.previewSize,
    this.isFrontCamera = true,
    required this.color,
  });

  final List<Rect> boxes;
  final Size previewSize;
  final bool isFrontCamera;
  final Color color;

  @override
  State<AnimatedFaceBox> createState() => _AnimatedFaceBoxState();
}

class _AnimatedFaceBoxState extends State<AnimatedFaceBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.boxes.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PremiumFaceBoxPainter(
            widget.boxes,
            widget.previewSize,
            isFrontCamera: widget.isFrontCamera,
            color: widget.color,
            scalePulse: _pulseAnimation.value,
          ),
        );
      },
    );
  }
}

class _PremiumFaceBoxPainter extends CustomPainter {
  const _PremiumFaceBoxPainter(
    this.boxes,
    this.previewSize, {
    required this.isFrontCamera,
    required this.color,
    required this.scalePulse,
  });

  final List<Rect> boxes;
  final Size previewSize;
  final bool isFrontCamera;
  final Color color;
  final double scalePulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;

    final scaleX = size.width / previewSize.width;
    final scaleY = size.height / previewSize.height;

    for (final box in boxes) {
      double left = box.left * scaleX;
      double right = box.right * scaleX;

      if (isFrontCamera) {
         final tmp = left;
         left = size.width - right;
         right = size.width - tmp;
      }

      final rect = Rect.fromLTRB(
        left,
        box.top * scaleY,
        right,
        box.bottom * scaleY,
      );

      // Save canvas state for scaling
      canvas.save();

      // Translate to center of rect
      final center = rect.center;
      canvas.translate(center.dx, center.dy);
      canvas.scale(scalePulse, scalePulse);
      canvas.translate(-center.dx, -center.dy);

      // Draw ambient glow
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withAlpha(20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawRect(rect, glowPaint);

      // Draw corner brackets
      final cornerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = color
        ..strokeCap = StrokeCap.round;

      const double cornerLength = 30.0;
      
      Path path = Path();
      
      // Top-Left
      path.moveTo(rect.left + cornerLength, rect.top);
      path.lineTo(rect.left, rect.top);
      path.lineTo(rect.left, rect.top + cornerLength);

      // Top-Right
      path.moveTo(rect.right - cornerLength, rect.top);
      path.lineTo(rect.right, rect.top);
      path.lineTo(rect.right, rect.top + cornerLength);

      // Bottom-Left
      path.moveTo(rect.left + cornerLength, rect.bottom);
      path.lineTo(rect.left, rect.bottom);
      path.lineTo(rect.left, rect.bottom - cornerLength);

      // Bottom-Right
      path.moveTo(rect.right - cornerLength, rect.bottom);
      path.lineTo(rect.right, rect.bottom);
      path.lineTo(rect.right, rect.bottom - cornerLength);

      canvas.drawPath(path, cornerPaint);

      // Restore canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PremiumFaceBoxPainter old) {
    return old.boxes != boxes ||
           old.isFrontCamera != isFrontCamera ||
           old.scalePulse != scalePulse ||
           old.color != color;
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({super.key});

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.0, _scanAnimation.value - 0.2),
              end: Alignment(0.0, _scanAnimation.value + 0.2),
              colors: [
                Colors.transparent,
                AppTheme.primaryAccent.withAlpha(20),
                AppTheme.primaryAccent.withAlpha(60),
                AppTheme.primaryAccent.withAlpha(20),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.face_unlock_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Looking for face...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

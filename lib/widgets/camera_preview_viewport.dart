import 'package:flutter/material.dart';

class CameraPreviewViewport extends StatelessWidget {
  const CameraPreviewViewport({
    super.key,
    required this.aspectRatio,
    required this.child,
  });

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return child;
        }

        final safeAspectRatio = aspectRatio > 0 ? aspectRatio : (3 / 4);
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final viewportAspectRatio = viewportWidth / viewportHeight;

        final double previewWidth;
        final double previewHeight;
        if (safeAspectRatio > viewportAspectRatio) {
          previewWidth = viewportWidth;
          previewHeight = previewWidth / safeAspectRatio;
        } else {
          previewHeight = viewportHeight;
          previewWidth = previewHeight * safeAspectRatio;
        }

        return Center(
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: child,
          ),
        );
      },
    );
  }
}

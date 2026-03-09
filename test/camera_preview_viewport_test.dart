import 'package:face_condition_detection/widgets/camera_preview_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses a contained layout so the preview keeps normal proportions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 600,
            child: CameraPreviewViewport(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                key: Key('preview_child'),
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );

    final previewSize = tester.getSize(find.byKey(const Key('preview_child')));
    expect(previewSize.width, 300);
    expect(previewSize.height, lessThan(600));
  });
}

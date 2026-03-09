import 'package:face_condition_detection/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('simulator user journey updates detected emotion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FaceConditionApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Simulator'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emotion_text')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.key == const Key('emotion_text') &&
            (widget.data?.contains('Neutral') ?? false),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('preset_happy')));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.key == const Key('emotion_text') &&
            (widget.data?.contains('Happy') ?? false),
      ),
      findsOneWidget,
    );
  });
}

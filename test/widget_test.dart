// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:fruit_nutrition_app/main.dart';

void main() {
  testWidgets('FruitPredictorPage smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(FruitApp());

    // Verify that the main UI loads.
    expect(find.text('Fruit Nutrition Predictor'), findsOneWidget);
    expect(find.text('Pick Image from Gallery'), findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splashtop_client/main.dart';

void main() {
  testWidgets('SplashTop Client smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the streaming screen
    expect(find.text('SplashTop Client - Test Mode'), findsOneWidget);
    
    // The app will show "No video stream" initially since WebSocket connection fails in test
    expect(find.text('No video stream'), findsOneWidget);
  });
}

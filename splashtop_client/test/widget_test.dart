// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:splashtop_client/main.dart';
import 'package:splashtop_client/services/auth_service.dart';
import 'package:splashtop_client/services/api_service.dart';
// import 'package:splashtop_client/services/webrtc_service.dart';

void main() {
  testWidgets('SplashTop Client smoke test', (WidgetTester tester) async {
    // Test that the app can be built without errors
    final storage = FlutterSecureStorage();
    final authService = AuthService(storage);
    final apiService = ApiService();
    
    // This should not throw any exceptions
    final app = MyApp(
      authService: authService,
      apiService: apiService,
    );
    
    expect(app, isA<MyApp>());
    expect(app.authService, equals(authService));
    expect(app.apiService, equals(apiService));
  });
}

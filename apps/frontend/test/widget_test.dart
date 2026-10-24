import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TienLoApp login screen smoke test', (WidgetTester tester) async {
    // Set viewport dimensions
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Build our app and trigger a frame.
    await tester.pumpWidget(const TienLoApp());
    await tester.pumpAndSettle();

    // Verify key titles and widgets exist on login screen
    expect(find.text('TienLo App'), findsOneWidget);
    expect(find.text('Đăng nhập với Google'), findsOneWidget);
    expect(find.text('Đăng nhập Thử nghiệm (Dev Demo)'), findsOneWidget);
  });
}

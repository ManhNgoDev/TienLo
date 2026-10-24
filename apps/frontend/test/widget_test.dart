import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tiên Lộ login screen smoke test', (WidgetTester tester) async {
    // Set viewport dimensions
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Build our app and trigger a frame.
    await tester.pumpWidget(const TienLoApp());
    await tester.pumpAndSettle();

    // Verify key titles and widgets exist on login screen
    expect(find.text('TIÊN LỘ'), findsOneWidget);
    expect(find.text('SẴN SÀNG NHẬP VAI?'), findsOneWidget);
    expect(find.text('Tạo nhân vật với Google'), findsOneWidget);
    expect(find.text('Tiến trình được đồng bộ'), findsOneWidget);
  });
}

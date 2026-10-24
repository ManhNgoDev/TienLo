import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('TienLo Monorepo UI smoke test', (WidgetTester tester) async {
    // Set a large enough surface size so all widgets fit without scrolling
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify key titles and widgets exist
    expect(find.text('TienLo Monorepo'), findsWidgets);
    expect(find.text('apps/backend'), findsOneWidget);
    expect(find.text('apps/frontend'), findsOneWidget);
    expect(find.text('Gửi Ping'), findsOneWidget);

    // Verify initial counter
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' button to increment counter
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify counter incremented
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

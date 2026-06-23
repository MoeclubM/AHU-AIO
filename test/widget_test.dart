// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:ahu_aio/main_layout_screen.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      GetMaterialApp(title: 'AHU AIO', home: const MainLayoutScreen()),
    );

    // Wait for the widget to load (limit animation frames to avoid timeout)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the app loads without errors
    expect(find.byType(MainLayoutScreen), findsOneWidget);
  });
}

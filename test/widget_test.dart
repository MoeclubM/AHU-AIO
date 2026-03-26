// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:ahu_aio/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      GetMaterialApp(title: 'AHU All In One', home: const HomePage()),
    );

    // Wait for the widget to settle
    await tester.pumpAndSettle();

    // Verify that the app loads without errors
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('AHU All In One'), findsOneWidget);
  });
}

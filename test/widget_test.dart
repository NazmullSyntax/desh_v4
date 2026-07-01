// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deshexplorer/config/app_config.dart';
import 'package:deshexplorer/main.dart';

void main() {
  test('Firebase backend is enabled by default', () {
    expect(AppConfig.useFirebase, isTrue);
  });

  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DeshExplorerApp()));
    await tester.pump(const Duration(seconds: 2));

    // Verify that the MaterialApp is created.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

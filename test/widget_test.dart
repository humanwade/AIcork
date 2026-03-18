import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wine_recommendation_app/main.dart';

void main() {
  testWidgets('App builds (smoke test)', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WineApp()));

    // Let splash timer complete to avoid pending timers.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    // The app uses MaterialApp.router; this verifies it renders.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

// Basic smoke tests for the Pro-Enroll app scaffold.
//
// These verify the app boots and exposes the brand name. We
// `pumpAndSettle` to drain the splash's auto-redirect timer so the test
// framework doesn't complain about pending timers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_enroll_app/app.dart';

void main() {
  testWidgets('App boots and shows the brand name', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProEnrollApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Pro-Enroll'), findsWidgets);
  });
}

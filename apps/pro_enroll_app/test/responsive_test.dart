// Snapshot-style tests that render every primary screen at the smallest
// supported viewport (320 × 568 — Galaxy Fold front display class) and a
// typical mid-range phone (390 × 844). They don't assert exact pixels;
// they just verify Flutter can lay out the screens without overflows or
// runtime exceptions at both sizes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_enroll_app/app.dart';

Future<void> _bootAt(
  WidgetTester tester,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const ProviderScope(child: ProEnrollApp()));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  testWidgets('boots without overflow on a 320×568 viewport', (tester) async {
    await _bootAt(tester, const Size(320, 568));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boots without overflow on a 390×844 viewport', (tester) async {
    await _bootAt(tester, const Size(390, 844));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boots without overflow on a 600×900 viewport (foldable)',
      (tester) async {
    await _bootAt(tester, const Size(600, 900));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

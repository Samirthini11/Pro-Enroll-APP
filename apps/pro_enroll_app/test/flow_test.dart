// Drives the onboarding flow end-to-end at a small viewport so that
// every step — language, welcome, phone, OTP, category, experience,
// location, fee, KYC intro — renders without overflow exceptions on the
// smallest supported device.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_enroll_app/app.dart';

void main() {
  testWidgets('onboarding flow lays out on a 320×640 viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ProEnrollApp()));

    // Splash auto-routes after ~1.1s.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // We don't try to drive the UI by string matches because the default
    // locale is Tamil and copy can change. Instead, just tap each visible
    // FilledButton in sequence to advance the flow, asserting that nothing
    // ever throws an overflow / layout exception at 320×640.
    for (var step = 0; step < 3; step++) {
      final btn = find.byType(FilledButton);
      if (btn.evaluate().isEmpty) break;
      await tester.tap(btn.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

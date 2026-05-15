// Drives both auth flows (sign-in shortcut + full sign-up onboarding)
// at a small viewport, ensuring every step renders and the user can
// reach the home shell without exceptions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_enroll_app/app.dart';

Future<void> _typePhone(WidgetTester tester, String phone) async {
  final phoneField = find.byType(TextField);
  await tester.enterText(phoneField.first, phone);
  await tester.pumpAndSettle();
}

Future<void> _typeOtp(WidgetTester tester, String otp) async {
  final otpField = find.byType(TextField);
  await tester.enterText(otpField.first, otp);
  await tester.pumpAndSettle();
}

Future<void> _tapPrimary(WidgetTester tester) async {
  // The visible primary CTA is always a FilledButton on these screens.
  await tester.tap(find.byType(FilledButton).first);
  // OTP send / verify in the mock repo is async with a small delay.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sign-in flow lands in the home shell on 360×740', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ProEnrollApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Auth landing has two CTAs. The first FilledButton is "Sign in".
    await tester.tap(find.text('Sign in').first);
    await tester.pumpAndSettle();

    await _typePhone(tester, '9812345678');
    await _tapPrimary(tester); // Send OTP

    await _typeOtp(tester, '123456');
    await _tapPrimary(tester); // Verify OTP → /home

    // Bottom nav of the home shell.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up flow advances into the onboarding wizard on 360×740',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ProEnrollApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap the "Create account · Enroll as a Pro" outlined button.
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();

    await _typePhone(tester, '9812345678');
    await _tapPrimary(tester); // Send OTP

    await _typeOtp(tester, '654321');
    await _tapPrimary(tester); // Verify OTP → /onboard/category

    // We should be on the category-select screen; the FilledButton "Next"
    // is initially disabled until a chip is tapped.
    expect(find.byType(FilledButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all viewports render the landing without overflow',
      (tester) async {
    for (final size in const [
      Size(320, 568),
      Size(360, 740),
      Size(390, 844),
      Size(600, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: ProEnrollApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

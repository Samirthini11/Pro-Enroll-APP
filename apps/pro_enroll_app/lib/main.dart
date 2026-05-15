import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // We try to initialise Firebase on every platform but gracefully
  // continue without it on platforms where we don't yet have a config
  // (currently iOS / Web). Phone OTP will fall back to the in-memory
  // mock implementation in `MockRepository` on those platforms.
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    try {
      await Firebase.initializeApp(options: options);
    } catch (_) {
      // Swallow — phone auth falls back to MockRepository.
    }
  }

  runApp(const ProviderScope(child: ProEnrollApp()));
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Current app locale (English / Tamil), persisted across launches.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _hydrate();
  }

  static const _prefsKey = 'app_language_code';

  /// Once the user picks a language (or hydrate finishes), ignore stale
  /// hydrate results so a late SharedPreferences read cannot overwrite.
  bool _locked = false;

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_locked) return;
      final code = prefs.getString(_prefsKey);
      if (code == null || code.isEmpty) return;
      final supported = supportedLanguages.any((l) => l.code == code);
      if (!supported || _locked) return;
      if (state.languageCode != code) {
        state = Locale(code);
      }
    } catch (_) {
      // Keep default English.
    } finally {
      _locked = true;
    }
  }

  Future<void> setLanguage(String code) async {
    final supported = supportedLanguages.any((l) => l.code == code);
    if (!supported) return;
    _locked = true;
    state = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (_) {}
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current app locale. Defaults to Tamil because the primary audience is
/// pros from Pondicherry, Karaikal and nearby Tamil Nadu.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ta'));

  void setLanguage(String code) => state = Locale(code);
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current app locale.
///
/// We default to **English** for v1 of the app so the early team can
/// build, demo and QA on a single language. Regional languages
/// (Tamil first, then Telugu / French) will become the recommended
/// default in a follow-up once translations are reviewed by native
/// speakers in the pilot region.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void setLanguage(String code) => state = Locale(code);
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

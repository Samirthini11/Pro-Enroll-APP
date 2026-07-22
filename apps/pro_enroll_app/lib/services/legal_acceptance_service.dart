import 'package:shared_preferences/shared_preferences.dart';

/// Persists Terms & Conditions acceptance (first launch after install).
class LegalAcceptanceService {
  static const _prefsKey = 'terms_accepted_version';

  /// Bump when terms text changes to re-prompt existing users.
  static const int currentTermsVersion = 1;

  Future<bool> hasAcceptedCurrentTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKey) == currentTermsVersion;
  }

  Future<void> acceptCurrentTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, currentTermsVersion);
  }
}

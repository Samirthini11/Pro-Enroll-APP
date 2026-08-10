import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets a professional explore the app while KYC is still under admin review.
class KycPreviewService {
  static const _prefsKey = 'kyc_preview_unlocked';

  static Future<bool> isUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) == true;
  }

  static Future<void> unlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final kycPreviewUnlockedProvider = StateProvider<bool>((ref) => false);

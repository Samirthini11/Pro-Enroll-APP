import 'package:shared_preferences/shared_preferences.dart';

import 'api/admin_mapper.dart';
import 'models.dart';

/// Persists admin JWT from `pro_enroll_api`.
class AdminTokenService {
  AdminTokenService({SharedPreferences? prefs})
      : _prefsFuture =
            prefs != null ? Future.value(prefs) : SharedPreferences.getInstance();

  static const _accessKey = 'admin_approval_access_token';
  static const _adminKey = 'admin_approval_user_json';

  final Future<SharedPreferences> _prefsFuture;
  String? _memoryAccess;
  AdminUser? _memoryAdmin;

  bool get hasToken => _memoryAccess != null && _memoryAccess!.isNotEmpty;

  Future<String?> getAccessToken() async {
    if (_memoryAccess != null && _memoryAccess!.isNotEmpty) {
      return _memoryAccess;
    }
    final prefs = await _prefsFuture;
    final stored = prefs.getString(_accessKey);
    if (stored != null && stored.isNotEmpty) {
      _memoryAccess = stored;
    }
    return stored;
  }

  Future<AdminUser?> getStoredAdmin() async {
    if (_memoryAdmin != null) return _memoryAdmin;
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_adminKey);
    if (raw == null || raw.isEmpty) return null;
    _memoryAdmin = adminUserFromStoredJson(raw);
    return _memoryAdmin;
  }

  Future<void> saveSession({
    required String accessToken,
    required AdminUser admin,
  }) async {
    _memoryAccess = accessToken;
    _memoryAdmin = admin;
    final prefs = await _prefsFuture;
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_adminKey, adminUserToJson(admin));
  }

  Future<void> signOut() async {
    _memoryAccess = null;
    _memoryAdmin = null;
    final prefs = await _prefsFuture;
    await prefs.remove(_accessKey);
    await prefs.remove(_adminKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Persists JWT tokens per role so the same phone can switch Pro ↔ Customer.
class JwtTokenService {
  JwtTokenService({SharedPreferences? prefs}) : _prefsFuture = prefs != null
      ? Future.value(prefs)
      : SharedPreferences.getInstance();

  static const _activeRoleKey = 'pro_active_role';
  static const _accessPro = 'pro_enroll_access_token_pro';
  static const _refreshPro = 'pro_enroll_refresh_token_pro';
  static const _sessionPro = 'pro_enroll_session_id_pro';
  static const _accessCustomer = 'pro_enroll_access_token_customer';
  static const _refreshCustomer = 'pro_enroll_refresh_token_customer';
  static const _sessionCustomer = 'pro_enroll_session_id_customer';

  final Future<SharedPreferences> _prefsFuture;
  AppRole? _activeRole;
  String? _memoryAccess;
  String? _memoryRefresh;
  String? _memorySession;

  bool get hasToken =>
      _memoryAccess != null && _memoryAccess!.isNotEmpty;

  /// True when a token exists in memory or persisted storage for the active role.
  Future<bool> hasTokenAsync() async {
    if (hasToken) return true;
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  Future<AppRole> getActiveRole() async {
    if (_activeRole != null) return _activeRole!;
    final prefs = await _prefsFuture;
    final stored = prefs.getString(_activeRoleKey);
    _activeRole = stored == 'customer' ? AppRole.customer : AppRole.professional;
    return _activeRole!;
  }

  Future<void> setActiveRole(AppRole role) async {
    _activeRole = role;
    final prefs = await _prefsFuture;
    await prefs.setString(
      _activeRoleKey,
      role == AppRole.customer ? 'customer' : 'professional',
    );
    // Reload persisted tokens for this role (switching must not leave memory empty).
    _memoryAccess = prefs.getString(_accessKey(role));
    _memoryRefresh = prefs.getString(_refreshKey(role));
    _memorySession = prefs.getString(_sessionKey(role));
  }

  String _accessKey(AppRole role) =>
      role == AppRole.customer ? _accessCustomer : _accessPro;

  String _refreshKey(AppRole role) =>
      role == AppRole.customer ? _refreshCustomer : _refreshPro;

  String _sessionKey(AppRole role) =>
      role == AppRole.customer ? _sessionCustomer : _sessionPro;

  Future<String?> getAccessToken() async {
    if (_memoryAccess != null && _memoryAccess!.isNotEmpty) {
      return _memoryAccess;
    }
    final role = await getActiveRole();
    final prefs = await _prefsFuture;
    final stored = prefs.getString(_accessKey(role));
    if (stored != null && stored.isNotEmpty) {
      _memoryAccess = stored;
    }
    return stored;
  }

  Future<String?> getRefreshToken() async {
    if (_memoryRefresh != null && _memoryRefresh!.isNotEmpty) {
      return _memoryRefresh;
    }
    final role = await getActiveRole();
    final prefs = await _prefsFuture;
    return prefs.getString(_refreshKey(role));
  }

  Future<String?> getSessionId() async {
    if (_memorySession != null) {
      return _memorySession;
    }
    final role = await getActiveRole();
    final prefs = await _prefsFuture;
    return prefs.getString(_sessionKey(role));
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? sessionId,
    AppRole? role,
  }) async {
    final active = role ?? await getActiveRole();
    await setActiveRole(active);

    _memoryAccess = accessToken;
    final prefs = await _prefsFuture;
    await prefs.setString(_accessKey(active), accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      _memoryRefresh = refreshToken;
      await prefs.setString(_refreshKey(active), refreshToken);
    }
    if (sessionId != null && sessionId.isNotEmpty) {
      _memorySession = sessionId;
      await prefs.setString(_sessionKey(active), sessionId);
    }
  }

  Future<void> saveAccessToken(String token) =>
      saveTokens(accessToken: token);

  /// Clears tokens for the active role only (keeps the other role's session).
  Future<void> signOut({bool allRoles = false}) async {
    final prefs = await _prefsFuture;
    if (allRoles) {
      _activeRole = null;
      _memoryAccess = null;
      _memoryRefresh = null;
      _memorySession = null;
      for (final key in [
        _accessPro,
        _refreshPro,
        _sessionPro,
        _accessCustomer,
        _refreshCustomer,
        _sessionCustomer,
        _activeRoleKey,
      ]) {
        await prefs.remove(key);
      }
      return;
    }

    final role = await getActiveRole();
    _memoryAccess = null;
    _memoryRefresh = null;
    _memorySession = null;
    await prefs.remove(_accessKey(role));
    await prefs.remove(_refreshKey(role));
    await prefs.remove(_sessionKey(role));
  }
}

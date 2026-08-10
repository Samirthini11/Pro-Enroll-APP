import '../jwt_token_service.dart';
import '../models.dart';
import '../repository.dart' show AuthSyncResult, OtpSendResult;
import 'api_client.dart';
import 'api_exception.dart';
import 'profile_mapper.dart';

/// PHP auth endpoints under `/v1/auth/*`.
class AuthApi {
  AuthApi(this._client, this._tokens);

  final ApiClient _client;
  final JwtTokenService _tokens;

  Future<OtpSendResult> sendOtp(String phone, {required String mode}) async {
    final data = await _client.post(
      '/v1/auth/otp/send',
      auth: false,
      body: {
        'phone_e164': phone,
        'mode': mode,
      },
    );
    final requestId = data['request_id'] as String? ?? '';
    if (requestId.isEmpty) {
      throw ApiException('OTP send failed: missing request_id', code: 'otp_send_failed');
    }
    return OtpSendResult(
      requestId: requestId,
      debugOtp: data['debug_otp'] as String?,
    );
  }

  Future<AuthSyncResult?> verifyOtp({
    required String requestId,
    required String otp,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) async {
    return _sessionFromResponse(
      () => _client.post(
        '/v1/auth/otp/verify',
        auth: false,
        body: {
          'request_id': requestId,
          'otp': otp,
          'mode': mode,
          'app': app,
        },
      ),
      invalidCodes: const {'invalid_otp'},
      role: role,
    );
  }

  Future<AuthSyncResult?> exchangeFirebaseSession({
    required String idToken,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) async {
    return _sessionFromResponse(
      () => _client.post(
        '/v1/auth/firebase/session',
        auth: false,
        body: {
          'id_token': idToken,
          'mode': mode,
          'app': app,
        },
      ),
      invalidCodes: const {'invalid_firebase_token'},
      role: role,
    );
  }

  Future<AuthSyncResult?> switchRole(AppRole role) async {
    final roleStr =
        role == AppRole.customer ? 'customer' : 'professional';
    return _sessionFromResponse(
      () => _client.post(
        '/v1/auth/switch-role',
        body: {'role': roleStr},
      ),
      invalidCodes: const {},
      role: role,
      clearTokensOnAuthFailure: false,
    );
  }

  Future<AuthSyncResult?> _sessionFromResponse(
    Future<Map<String, dynamic>> Function() request, {
    required Set<String> invalidCodes,
    AppRole role = AppRole.professional,
    bool clearTokensOnAuthFailure = true,
  }) async {
    Map<String, dynamic> data;
    try {
      data = await request();
    } on ApiException catch (e) {
      if (clearTokensOnAuthFailure &&
          (invalidCodes.contains(e.code) || e.statusCode == 401)) {
        await _tokens.signOut();
      }
      rethrow;
    }

    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access == null || access.isEmpty) {
      return null;
    }

    await _tokens.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      sessionId: data['session_id'] as String?,
      role: role,
    );

    final apiRole = data['role'] as String?;
    final resolvedRole = apiRole == 'customer'
        ? AppRole.customer
        : AppRole.professional;

    return AuthSyncResult(
      nextRoute: data['next_route'] as String? ?? '/onboard/category',
      profile: profileFromApiMap(
        data['profile'] as Map<String, dynamic>?,
      ),
      role: resolvedRole,
    );
  }

  Future<bool> refreshAccessToken() async {
    final refresh = await _tokens.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return false;
    }

    final data = await _client.post(
      '/v1/auth/refresh',
      auth: false,
      body: {'refresh_token': refresh},
    );

    final access = data['access_token'] as String?;
    if (access == null || access.isEmpty) {
      return false;
    }

    await _tokens.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      sessionId: data['session_id'] as String?,
    );
    return true;
  }

  Future<bool> validateSession() async {
    try {
      final data = await _client.get('/v1/auth/validate');
      return data['valid'] == true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          try {
            final data = await _client.get('/v1/auth/validate');
            return data['valid'] == true;
          } on ApiException catch (e2) {
            if (e2.statusCode == 401) return false;
            // Server/network flake after refresh — keep session.
            return true;
          } catch (_) {
            return true;
          }
        }
        return false;
      }
      // Non-auth API errors (5xx / timeout wrappers) — keep local session.
      return true;
    } catch (_) {
      // Network unreachable during cold start — keep local session.
      return true;
    }
  }

  Future<ProProfile?> fetchMe() async {
    final data = await _client.get('/v1/auth/me');
    return profileFromApiMap(data['profile'] as Map<String, dynamic>?);
  }

  /// Revokes the current JWT session on the server (`POST /v1/auth/logout`).
  Future<void> logout() async {
    await _client.post('/v1/auth/logout');
  }
}

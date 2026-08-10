import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../jwt_token_service.dart';
import 'api_exception.dart';
import 'ifree_cookie_solver.dart';

class ApiClient {
  ApiClient(this._tokens, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final JwtTokenService _tokens;
  final http.Client _http;
  final IFreeCookieSolver _ifreeSolver = IFreeCookieSolver();

  String get _base => AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) =>
      _request('GET', path, auth: auth, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    bool auth = true,
    Map<String, dynamic>? body,
  }) =>
      _request('POST', path, auth: auth, body: body);

  Future<Map<String, dynamic>> put(
    String path, {
    bool auth = true,
    Map<String, dynamic>? body,
  }) =>
      _request('PUT', path, auth: auth, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    required bool auth,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool retried = false,
  }) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _tokens.getAccessToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Sign in required for API calls', code: 'no_token');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    _ifreeSolver.applyToHeaders(headers);

    late http.Response response;
    try {
      response = await _send(method, uri, headers, body);
      response = await _maybeRetryAfterChallenge(method, uri, headers, body, response);
    } on http.ClientException catch (e) {
      throw ApiException(
        'Cannot reach API at $_base. Live: ${AppConfig.liveApiBaseUrl} | '
        'Local: ${AppConfig.localApiBaseUrl}',
        code: 'network',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', code: 'network');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (_ifreeSolver.isChallengePage(response)) {
        throw ApiException(
          'Hosting blocked the request (bot challenge page). '
          'Try local API: --dart-define=API_BASE_URL=http://localhost:8080',
          statusCode: response.statusCode,
          code: 'hosting_challenge',
        );
      }
      throw ApiException(
        'Invalid API response (${response.statusCode}) from $_base. '
        'Live: ${AppConfig.liveApiBaseUrl} | Local: ${AppConfig.localApiBaseUrl} '
        '(use --dart-define=USE_LOCAL_API=true for localhost).',
        statusCode: response.statusCode,
        code: 'invalid_json',
      );
    }

    final success = decoded['success'] == true;
    if (!success) {
      final err = decoded['error'];
      final code = err is Map ? err['code'] as String? : null;

      if (auth &&
          !retried &&
          response.statusCode == 401 &&
          (code == 'invalid_token' || code == 'session_revoked')) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _request(
            method,
            path,
            auth: auth,
            query: query,
            body: body,
            retried: true,
          );
        }
      }

      final message = err is Map
          ? (err['message'] as String? ?? 'Request failed')
          : 'Request failed';
      throw ApiException(message, statusCode: response.statusCode, code: code);
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return {};
    return {'value': data};
  }

  Future<http.Response> _maybeRetryAfterChallenge(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
    http.Response response,
  ) async {
    if (!_ifreeSolver.isChallengePage(response)) {
      return response;
    }

    final solved = await _ifreeSolver.solveFromResponse(response);
    if (!solved) {
      return response;
    }

    _ifreeSolver.applyToHeaders(headers);
    var retried = await _send(method, uri, headers, body);
    if (_ifreeSolver.isChallengePage(retried)) {
      final withFlag = uri.replace(
        queryParameters: {...uri.queryParameters, 'i': '1'},
      );
      retried = await _send(method, withFlag, headers, body);
    }
    return retried;
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );
      case 'POST':
        return _http
            .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
            .timeout(const Duration(seconds: 15));
      case 'PUT':
        return _http
            .put(uri, headers: headers, body: body == null ? null : jsonEncode(body))
            .timeout(const Duration(seconds: 15));
      default:
        throw ApiException('Unsupported method $method');
    }
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await _tokens.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse('$_base/v1/auth/refresh');
      final response = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return false;
      }

      final data = decoded['data'] as Map<String, dynamic>?;
      final access = data?['access_token'] as String?;
      if (access == null || access.isEmpty) {
        return false;
      }

      await _tokens.saveTokens(
        accessToken: access,
        refreshToken: refresh,
        sessionId: data?['session_id'] as String?,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _http.close();
}

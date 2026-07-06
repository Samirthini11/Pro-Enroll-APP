import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../admin_token_service.dart';
import 'api_exception.dart';
import 'ifree_cookie_solver.dart';

class ApiClient {
  ApiClient(this._tokens, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final AdminTokenService _tokens;
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

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    required bool auth,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _tokens.getAccessToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Sign in required', code: 'no_token');
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
        'Cannot reach API at $_base. Check your internet connection.',
        code: 'network',
      );
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      final msg = e.toString();
      if (msg.contains('TimeoutException') || msg.contains('timed out')) {
        throw ApiException(
          'API request timed out. Check network and try again.',
          code: 'timeout',
        );
      }
      throw ApiException('Network error: $e', code: 'network');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (_ifreeSolver.isChallengePage(response)) {
        throw ApiException(
          'Hosting blocked the request (bot challenge). Try again in a moment.',
          statusCode: response.statusCode,
          code: 'hosting_challenge',
        );
      }
      throw ApiException(
        'Invalid API response (${response.statusCode}) from $_base',
        statusCode: response.statusCode,
        code: 'invalid_json',
      );
    }

    if (decoded['success'] != true) {
      final err = decoded['error'];
      final code = err is Map ? err['code'] as String? : null;
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
    if (!_ifreeSolver.isChallengePage(response)) return response;

    final solved = await _ifreeSolver.solveFromResponse(response);
    if (!solved) return response;

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
            .post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
      default:
        throw ApiException('Unsupported method $method');
    }
  }

  void dispose() => _http.close();
}

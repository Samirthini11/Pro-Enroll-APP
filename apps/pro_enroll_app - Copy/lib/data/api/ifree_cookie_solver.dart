import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;

/// Solves InfinityFree's AES JavaScript challenge and caches the
/// resulting `__test` cookie so subsequent API requests pass through.
class IFreeCookieSolver {
  String? _cookie;
  DateTime? _expiresAt;

  String? get cookie {
    if (_cookie == null) return null;
    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
      _cookie = null;
      _expiresAt = null;
      return null;
    }
    return _cookie;
  }

  bool isChallengePage(http.Response response) {
    if (response.body.length > 5000) return false;
    return response.body.contains('slowAES.decrypt') &&
        response.body.contains('__test');
  }

  /// Parse a, b, c hex values from the challenge HTML and compute the cookie.
  Future<bool> solveFromResponse(http.Response response) async {
    try {
      final body = response.body;

      final pattern = RegExp(
        r'toNumbers\("([a-f0-9]+)"\)\s*\)\s*,'
        r'\s*b\s*=\s*toNumbers\(\s*"([a-f0-9]+)"\s*\)\s*,'
        r'\s*c\s*=\s*toNumbers\(\s*"([a-f0-9]+)"\s*\)',
      );
      var match = pattern.firstMatch(body);

      if (match == null) {
        final aMatch = RegExp(r'var a\s*=\s*toNumbers\("([a-f0-9]+)"\)').firstMatch(body);
        final bMatch = RegExp(r'b\s*=\s*toNumbers\("([a-f0-9]+)"\)').firstMatch(body);
        final cMatch = RegExp(r'c\s*=\s*toNumbers\("([a-f0-9]+)"\)').firstMatch(body);
        if (aMatch == null || bMatch == null || cMatch == null) return false;

        final aHex = aMatch.group(1)!;
        final bHex = bMatch.group(1)!;
        final cHex = cMatch.group(1)!;
        _cookie = _decrypt(aHex, bHex, cHex);
      } else {
        _cookie = _decrypt(match.group(1)!, match.group(2)!, match.group(3)!);
      }

      _expiresAt = DateTime.now().add(const Duration(hours: 5));
      return _cookie != null;
    } catch (_) {
      return false;
    }
  }

  String? _decrypt(String keyHex, String ivHex, String cipherHex) {
    try {
      final key = Key(Uint8List.fromList(_hexToBytes(keyHex)));
      final iv = IV(Uint8List.fromList(_hexToBytes(ivHex)));
      final encrypted = Encrypted(Uint8List.fromList(_hexToBytes(cipherHex)));

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: null));
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

      return decrypted
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    } catch (_) {
      return null;
    }
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  Map<String, String> applyToHeaders(Map<String, String> headers) {
    final c = cookie;
    if (c == null) return headers;
    final existing = headers['Cookie'] ?? '';
    final cookieStr = '__test=$c';
    headers['Cookie'] = existing.isEmpty ? cookieStr : '$existing; $cookieStr';
    return headers;
  }
}

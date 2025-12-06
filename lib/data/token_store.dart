import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyBaseUrl = 'base_url';
  static const _keySid = 'sid';
  static const _keyEmail = 'email';

  Future<SessionToken?> read() async {
    final values = await _storage.readAll();
    final baseUrl = values[_keyBaseUrl];
    final sid = values[_keySid];
    final email = values[_keyEmail];
    if (baseUrl == null || sid == null || email == null) {
      return null;
    }
    return SessionToken(baseUrl: baseUrl, sid: sid, email: email);
  }

  Future<void> save({
    required String baseUrl,
    required String sid,
    required String email,
  }) async {
    final cleanUrl = _normalizeBaseUrl(baseUrl);
    await _storage.write(key: _keyBaseUrl, value: cleanUrl);
    await _storage.write(key: _keySid, value: sid);
    await _storage.write(key: _keyEmail, value: email);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyBaseUrl);
    await _storage.delete(key: _keySid);
    await _storage.delete(key: _keyEmail);
  }

  String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) return trimmed;
    return '$trimmed/';
  }
}

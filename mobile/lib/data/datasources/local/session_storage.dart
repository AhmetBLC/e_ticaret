import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';

/// Persists JWT in secure storage; caches non-sensitive user snapshot in prefs.
class SessionStorage {
  SessionStorage(
    this._prefs, {
    FlutterSecureStorage? secureStorage,
  }) : _secure = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const _secureTokenKey = 'auth_jwt';
  /// Legacy key when token lived in SharedPreferences (migrated once).
  static const _legacyPrefsTokenKey = 'auth_token';
  static const _userKey = 'cached_user_json';

  Future<String?> readToken() async {
    final secure = await _secure.read(key: _secureTokenKey);
    if (secure != null && secure.isNotEmpty) {
      return secure;
    }
    final legacy = _prefs.getString(_legacyPrefsTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: _secureTokenKey, value: legacy);
      await _prefs.remove(_legacyPrefsTokenKey);
      return legacy;
    }
    return null;
  }

  Future<void> writeToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _secure.delete(key: _secureTokenKey);
      await _prefs.remove(_legacyPrefsTokenKey);
    } else {
      await _secure.write(key: _secureTokenKey, value: token);
      await _prefs.remove(_legacyPrefsTokenKey);
    }
  }

  Future<void> cacheUser(UserModel user) async {
    await _prefs.setString(
      _userKey,
      jsonEncode({
        'id': user.id,
        'email': user.email,
        'created_at': user.createdAt.toIso8601String(),
        if (user.role != null) 'role': user.role,
      }),
    );
  }

  Future<UserModel?> readCachedUser() async {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUserCache() async {
    await _prefs.remove(_userKey);
  }

  Future<void> clearAll() async {
    await writeToken(null);
    await clearUserCache();
  }
}

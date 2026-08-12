import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  static const _tokenKey = 'sportx_auth_token';
  static const _userKey = 'sportx_user_data';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    // Persist as JSON so nested values, lists and types survive a round-trip
    // (the previous k=v&k=v encoding corrupted values containing & or =).
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

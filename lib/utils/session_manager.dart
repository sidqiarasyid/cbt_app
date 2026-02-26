import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const String _tokenKey = 'token';

  // Use secure storage for sensitive data (token)
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Token - stored securely
  static Future<void> setToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  static Future<void> removeToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // Clear all session data
  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _tokenKey = 'token';
  static const String _profileImageKey = 'profile_image';

  // Token
  static Future<void> setToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Static method to get the token quickly
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Profile image is stored as base64 string in SharedPreferences
  static Future<void> setProfileImage(String base64Image) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, base64Image);
  }

  static Future<String?> getProfileImage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }
}

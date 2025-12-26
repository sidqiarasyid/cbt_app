import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _tokenKey = 'token';

  // Static method to get the token quickly
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }


}
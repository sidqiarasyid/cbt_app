import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/user_model.dart';
import 'package:cbt_app/services/auth_service.dart';
import 'package:cbt_app/services/profile_service.dart';
import 'package:cbt_app/utils/session_manager.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, ProfileService? profileService})
      : _authService = authService ?? AuthService(),
        _profileService = profileService ?? ProfileService();

  final AuthService _authService;
  final ProfileService _profileService;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  String? _displayName;
  String? get displayName => _displayName;

  /// Called on app start to check whether the stored token is still valid.
  Future<void> bootstrap() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    try {
      await _profileService.fetchProfile();
      final prefs = await SharedPreferences.getInstance();
      _displayName = prefs.getString('username');
      _setStatus(AuthStatus.authenticated);
    } catch (_) {
      await SessionManager.clearAll();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<UserModel> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Isi Username dan Password terlebih dahulu');
    }
    final res = await _authService.loginStudent(username, password);
    await SessionManager.setToken(res.token);
    final prefs = await SharedPreferences.getInstance();
    final name = res.user.profile.fullName.isNotEmpty
        ? res.user.profile.fullName
        : username;
    await prefs.setString('username', name);
    _displayName = name;
    _setStatus(AuthStatus.authenticated);
    return res;
  }

  Future<void> logout() async {
    try {
      await _authService.serverLogout();
    } catch (_) {
      // proceed with local cleanup either way
    }
    await SessionManager.clearAll();
    _displayName = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus next) {
    if (_status == next) return;
    _status = next;
    notifyListeners();
  }
}

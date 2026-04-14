import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/user_model.dart';
import 'package:cbt_app/services/login_service.dart';
import 'package:cbt_app/utils/session_manager.dart';
import 'package:cbt_app/utils/url.dart';
import 'package:cbt_app/views/login_page.dart';
import 'package:cbt_app/utils/page_transitions.dart';

class AuthController {
  final LoginService _loginService = LoginService();

  /// Melakukan login siswa
  /// Returns [UserModel] jika berhasil, throws Exception jika gagal
  Future<UserModel> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Isi Username dan Password terlebih dahulu');
    }

    final res = await _loginService.loginSiswa(username, password);

    // Always save token on successful login
    await SessionManager.setToken(res.token);
    final prefs = await SharedPreferences.getInstance();
    final displayName = res.user.profile.fullName.isNotEmpty 
        ? res.user.profile.fullName 
        : username;
    await prefs.setString('username', displayName);

    return res;
  }

  /// Melakukan logout, log ke server, dan clear session
  Future<void> logout() async {
    // Call logout API to create activity log
    try {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('${Url.emuUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Proceed with local cleanup even if API call fails
    }
    await SessionManager.clearAll();
  }

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final token = await SessionManager.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Mendapatkan token yang tersimpan
  Future<String?> getToken() async {
    return await SessionManager.getToken();
  }

  /// Mendapatkan username yang tersimpan
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  /// Navigasi ke halaman login setelah logout
  void navigateToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      fadeSlideRoute(const Loginpage()),
      (route) => false,
    );
  }

  /// Menampilkan dialog konfirmasi logout
  Future<bool?> showLogoutConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF44336), Color(0xFFC62828)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                "Konfirmasi Logout",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Apakah anda yakin ingin keluar dari akun ini?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF44336), Color(0xFFC62828)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF44336).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Ya, Keluar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/user_model.dart';
import 'package:cbt_app/services/login_service.dart';
import 'package:cbt_app/views/login_page.dart';

class AuthController {
  final LoginService _loginService = LoginService();

  /// Melakukan login siswa
  /// Returns [UserModel] jika berhasil, throws Exception jika gagal
  Future<UserModel> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Isi Username dan Password terlebih dahulu');
    }

    final res = await _loginService.loginSiswa(username, password);

    if (res.user.profile.namaLengkap.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.token);
      await prefs.setString('username', res.user.profile.namaLengkap);
    }

    return res;
  }

  /// Melakukan logout dan clear session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// Mendapatkan token yang tersimpan
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
      MaterialPageRoute(builder: (context) => const Loginpage()),
      (route) => false,
    );
  }

  /// Menampilkan dialog konfirmasi logout
  Future<bool?> showLogoutConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF11B1E2).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_outlined, color: Color(0xFF11B1E2)),
            ),
            const SizedBox(width: 12),
            const Text('Konfirmasi Logout'),
          ],
        ),
        content: const Text('Apakah anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11B1E2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/config/env.dart';
import 'package:http/http.dart' as http;

import 'package:cbt_app/models/user_model.dart';
import 'package:cbt_app/utils/session_manager.dart';

class AuthService {
  /// Notify the server about logout so it can record an activity log.
  /// Silent on failure - caller still proceeds with local cleanup.
  Future<void> serverLogout() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return;
    await http
        .post(
          Uri.parse('${Env.apiBaseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 5));
  }


  Future<UserModel> loginStudent(String username, String password) async {
    final url = Uri.parse('${Env.apiBaseUrl}/auth/login');
    final Map<String, dynamic> body = {
      'username': username,
      'password': password,
    };

    final String bodyJson = jsonEncode(body);
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: bodyJson,
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        final userModel = UserModel.fromJson(bodyMap);
        
        // Only allow student role on mobile app
        if (userModel.user.role.toLowerCase() != 'student') {
          throw Exception('Aplikasi ini hanya untuk siswa. Gunakan dashboard web untuk guru/admin.');
        }
        
        return userModel;
      } else {
        // Parse error message from response
        String errorMessage = 'Login gagal';
        try {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);
          errorMessage = errorBody['error'] ?? 'Login gagal';
        } catch (_) {
          // ignore parse errors
        }

        // Unified error message - don't differentiate between wrong user/password
        if (response.statusCode == 401 || response.statusCode == 404) {
          throw Exception('Username atau password salah');
        } else if (response.statusCode == 403) {
          throw Exception('Akun dinonaktifkan');
        } else {
          throw Exception(errorMessage);
        }
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout, silakan coba lagi');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server');
    }
  }
}

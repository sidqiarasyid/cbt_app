import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/utlis/url.dart';
import 'package:http/http.dart' as http;

import 'package:cbt_app/model/user_model.dart';

class LoginService {
  final url = Uri.parse('${Url.emuUrl}/auth/login');

  Future<UserModel> loginSiswa(String username, String password) async {
    final Map<String, dynamic> body = {
      "username": username,
      "password": password,
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
        return UserModel.fromJson(bodyMap);
      } else {
        // Parse error message from response
        String errorMessage = 'Login gagal';
        try {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);
          errorMessage = errorBody['error'] ?? 'Login gagal';
        } catch (e) {
          print('Failed to parse error body: $e');
        }

        print('Login failed: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Throw exception with specific error message
        if (response.statusCode == 401) {
          throw Exception('Password salah');
        } else if (response.statusCode == 404) {
          throw Exception('User tidak ditemukan');
        } else if (response.statusCode == 403) {
          throw Exception('Akun dinonaktifkan');
        } else {
          throw Exception(errorMessage);
        }
      }
    } on TimeoutException catch (e) {
      print('Request timed out: $e');
      throw Exception('Koneksi timeout, silakan coba lagi');
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception('Tidak dapat terhubung ke server');
    }
  }
}

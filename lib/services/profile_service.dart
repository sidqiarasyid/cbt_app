import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:cbt_app/utils/session_manager.dart';
import 'package:cbt_app/models/user_model.dart';

class ProfileService {
  String _friendlyError(int statusCode, String action) {
    switch (statusCode) {
      case 401:
        return 'Sesi telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki izin untuk $action.';
      case 404:
        return 'Data profil tidak ditemukan.';
      case 500:
        return 'Terjadi kesalahan pada server. Coba lagi nanti.';
      default:
        return 'Gagal $action. Silakan coba lagi.';
    }
  }
  Future<UserModel> fetchProfile() async {
    final Uri meUrl = Uri.parse('${Url.emuUrl}/auth/me');
    final String? token = await SessionManager.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .get(
          meUrl,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        )
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final userModel = UserModel.fromJson(body);

      // DO NOT persist profile fields locally here. Only the photo is stored in SharedPreferences per requirement.
      return userModel;
    } else {
      throw Exception(_friendlyError(response.statusCode, 'mengambil profil'));
    }
  }

  // Update profile on server. Backend contract may vary; adapt body keys.
  Future<UserModel> updateProfile({
    required String fullName,
    required String role,
    String? classroom,
    String? major,
    String? gradeLevel,
  }) async {
    final Uri updateUrl = Uri.parse('${Url.emuUrl}/auth/profile');
    final String? token = await SessionManager.getToken();
    if (token == null) throw Exception('Not authenticated');

    final Map<String, dynamic> body = {
      'full_name': fullName,
      'role': role,
      if (classroom != null) 'classroom': classroom,
      if (major != null) 'major': major,
      if (gradeLevel != null) 'grade_level': gradeLevel,
    };

    final response = await http
        .patch(
          updateUrl,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> bodyMap = jsonDecode(response.body);
      final userModel = UserModel.fromJson(bodyMap);

      return userModel;
    } else {
      throw Exception(_friendlyError(response.statusCode, 'mengubah profil'));
    }
  }

  /// Change password for the authenticated user.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final Uri changePasswordUrl = Uri.parse('${Url.emuUrl}/auth/change-password');
    final String? token = await SessionManager.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .patch(
          changePasswordUrl,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return;
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['error'] ?? _friendlyError(response.statusCode, 'mengubah password'));
    }
  }
}

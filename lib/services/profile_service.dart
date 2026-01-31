import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:cbt_app/utils/session_manager.dart';
import 'package:cbt_app/models/user_model.dart';

class ProfileService {
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
      throw Exception('Gagal mengambil profile: ${response.statusCode}');
    }
  }

  // Update profile on server. Backend contract may vary; adapt body keys.
  Future<UserModel> updateProfile({
    required String namaLengkap,
    required String role,
    String? kelas,
    String? jurusan,
    String? tingkat,
  }) async {
    final Uri updateUrl = Uri.parse('${Url.emuUrl}/profile');
    final String? token = await SessionManager.getToken();
    if (token == null) throw Exception('Not authenticated');

    final Map<String, dynamic> body = {
      'nama_lengkap': namaLengkap,
      'role': role,
      if (kelas != null) 'kelas': kelas,
      if (jurusan != null) 'jurusan': jurusan,
      if (tingkat != null) 'tingkat': tingkat,
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

      // DO NOT persist profile fields locally here. Only the photo is stored in SharedPreferences per requirement.
      return userModel;
    } else {
      throw Exception('Gagal update profile: ${response.statusCode}');
    }
  }
}

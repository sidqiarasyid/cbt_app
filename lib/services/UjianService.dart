import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/model/ujian_response_model.dart';
import 'package:cbt_app/utlis/session_manager.dart';
import 'package:cbt_app/utlis/url.dart';
import 'package:http/http.dart' as http;

class UjianService {
  Future<UjianResponseModel> getUjianSiswa() async {
    final token = await SessionManager.getToken();
    
    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('${Url.emuUrl}/siswa/ujians');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        return UjianResponseModel.fromJson(bodyMap);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception('Data ujian tidak ditemukan.');
      } else {
        print('Get ujian failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw HttpException('Error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Request timed out: $e');
      throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
    } on SocketException catch (e) {
      print('Socket exception: $e');
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } catch (e) {
      print('Error getting ujian: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}

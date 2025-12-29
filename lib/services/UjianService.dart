import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/model/start_ujian_response_model.dart';
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
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 10));

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
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      print('Error getting ujian: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Start Ujian - Mulai ujian dan get daftar soal
  Future<StartUjianResponseModel> startUjian(int pesertaUjianId) async {
    final token = await SessionManager.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('${Url.emuUrl}/siswa/ujians/start');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'peserta_ujian_id': pesertaUjianId}),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        print('✅ Start Ujian Success: Peserta $pesertaUjianId');
        return StartUjianResponseModel.fromJson(bodyMap);
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        throw Exception(bodyMap['error'] ?? 'Gagal memulai ujian');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else {
        print('Start ujian failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw HttpException('Error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Request timed out: $e');
      throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
    } on SocketException catch (e) {
      print('Socket exception: $e');
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      print('Error starting ujian: $e');
      rethrow;
    }
  }

  // Submit Jawaban - Submit jawaban per soal (auto-save)
  Future<void> submitJawaban({
    required int pesertaUjianId,
    required int soalId,
    int? opsiJawabanId,
    List<int>? opsiJawabanIds,
    String? teksJawaban,
  }) async {
    final token = await SessionManager.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('${Url.emuUrl}/siswa/ujians/jawaban');

    try {
      final Map<String, dynamic> body = {
        'peserta_ujian_id': pesertaUjianId,
        'soal_id': soalId,
      };

      if (opsiJawabanId != null) {
        body['opsi_jawaban_id'] = opsiJawabanId;
      }

      if (opsiJawabanIds != null && opsiJawabanIds.isNotEmpty) {
        body['opsi_jawaban_ids'] = opsiJawabanIds;
      }

      if (teksJawaban != null) {
        body['teks_jawaban'] = teksJawaban;
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Jawaban tersimpan: Soal $soalId');
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        print('⚠️ Submit jawaban warning: ${bodyMap['error']}');
        throw Exception(bodyMap['error'] ?? 'Gagal menyimpan jawaban');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else {
        print('Submit jawaban failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw HttpException('Error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('⚠️ Timeout submit jawaban soal $soalId: $e');
      throw Exception('Koneksi timeout. Jawaban mungkin belum tersimpan.');
    } on SocketException catch (e) {
      print('⚠️ Socket exception submit jawaban soal $soalId: $e');
      throw Exception(
        'Tidak dapat terhubung ke server. Jawaban akan disimpan lokal.',
      );
    } catch (e) {
      print('⚠️ Error submit jawaban soal $soalId: $e');
      rethrow;
    }
  }

  // Finish Ujian - Selesaikan ujian dan hitung nilai
  Future<Map<String, dynamic>> finishUjian(int pesertaUjianId) async {
    final token = await SessionManager.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('${Url.emuUrl}/siswa/ujians/finish');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'peserta_ujian_id': pesertaUjianId}),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        print('✅ Ujian selesai: ${bodyMap['message']}');
        return bodyMap;
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        throw Exception(bodyMap['error'] ?? 'Gagal menyelesaikan ujian');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else {
        print('Finish ujian failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw HttpException('Error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Request timed out: $e');
      throw Exception('Koneksi timeout. Coba lagi.');
    } on SocketException catch (e) {
      print('Socket exception: $e');
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      print('Error finishing ujian: $e');
      rethrow;
    }
  }
}

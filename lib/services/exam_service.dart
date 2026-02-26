import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/models/start_exam_response_model.dart';
import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/models/exam_result_response_model.dart';
import 'package:cbt_app/utils/session_manager.dart';
import 'package:cbt_app/utils/url.dart';
import 'package:http/http.dart' as http;

class ExamService {
  Future<ExamResponseModel> getStudentExams() async {
    final token = await SessionManager.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

      final url = Uri.parse('${Url.emuUrl}/students/exams');

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
        return ExamResponseModel.fromJson(bodyMap);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception('Exam data not found.');
      } else {
        throw HttpException('Terjadi kesalahan pada server.');
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      rethrow;
    }
  }

    // Get Exam Results - list of exam results for current student
    Future<ExamResultListResponse> getStudentExamResults() async {
      final token = await SessionManager.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final url = Uri.parse('${Url.emuUrl}/exam-results/my-results');

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
          return ExamResultListResponse.fromJson(bodyMap);
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized. Silakan login kembali.');
        } else if (response.statusCode == 404) {
          throw Exception('Exam results data not found.');
        } else {
          throw HttpException('Terjadi kesalahan pada server.');
        }
      } on TimeoutException {
        throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
      } on SocketException {
        throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      } catch (e) {
        rethrow;
      }
    }
  // Start Exam - Start exam and get question list
  Future<StartExamResponseModel> startExam(int examId) async {
    final token = await SessionManager.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('${Url.emuUrl}/students/exams/start');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'exam_id': examId}),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        return StartExamResponseModel.fromJson(bodyMap);
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        throw Exception(bodyMap['error'] ?? 'Failed to start exam');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else {
        throw HttpException('Terjadi kesalahan pada server.');
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Submit Answer - Submit answer per question (auto-save)
  Future<void> submitAnswer({
    required int examParticipantId,
    required int questionId,
    int? answerOptionId,
    List<int>? answerOptionIds,
    String? answerText,
  }) async {
    final token = await SessionManager.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('${Url.emuUrl}/students/exams/answer');

    try {
      final Map<String, dynamic> body = {
        'exam_participant_id': examParticipantId,
        'question_id': questionId,
      };

      // Backend expects mc_option_ids (array or single value) for MC questions
      if (answerOptionId != null) {
        body['mc_option_ids'] = [answerOptionId];
      }

      if (answerOptionIds != null) {
        body['mc_option_ids'] = answerOptionIds;
      }

      // Backend expects essay_answer_text for essay questions
      if (answerText != null) {
        body['essay_answer_text'] = answerText;
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
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        throw Exception(bodyMap['error'] ?? 'Failed to save answer');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else {
        throw HttpException('Terjadi kesalahan pada server.');
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout. Jawaban mungkin belum tersimpan.');
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Jawaban akan disimpan lokal.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Finish Exam - Complete exam and calculate score
  Future<Map<String, dynamic>> finishExam(int examParticipantId) async {
    final token = await SessionManager.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('${Url.emuUrl}/students/exams/finish');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'exam_participant_id': examParticipantId}),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        return bodyMap;
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        throw Exception(bodyMap['error'] ?? 'Failed to finish exam');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Silakan login kembali.');
      } else {
        throw HttpException('Terjadi kesalahan pada server.');
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi.');
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Report Violation - Student self-reports app lifecycle violation (anti-cheat)
  Future<void> reportViolation({
    required int examParticipantId,
    required String violationType,
  }) async {
    final token = await SessionManager.getToken();

    if (token == null) return; // Silent fail - local block already set

    final url = Uri.parse('${Url.emuUrl}/students/exams/report-violation');

    try {
      await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'exam_participant_id': examParticipantId,
              'violation_type': violationType,
            }),
          )
          .timeout(Duration(seconds: 5));
    } catch (_) {
      // Fire-and-forget: local block is already set via SharedPreferences.
      // Server sync will happen on next exam start attempt.
    }
  }
}

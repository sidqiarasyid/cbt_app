import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/ujian_model.dart';
import 'package:cbt_app/models/ujian_response_model.dart';
import 'package:cbt_app/models/hasil_ujian_response_model.dart';
import 'package:cbt_app/services/ujian_service.dart';
import 'package:cbt_app/utils/helpers.dart';

class UjianController {
  final UjianService _ujianService = UjianService();

  /// Mengambil daftar ujian untuk siswa
  Future<UjianResponseModel> getUjianList() {
    return _ujianService.getUjianSiswa();
  }

  /// Mengambil daftar hasil ujian siswa
  Future<HasilUjianListResponse> getHasilUjian() {
    return _ujianService.getHasilUjianSiswa();
  }

  /// Memulai ujian dan return UjianModel yang siap digunakan
  Future<UjianModel> startUjian(
    PesertaUjian pesertaUjian,
    String namaUjian,
    DateTime tanggalMulai,
  ) async {
    final startUjianResponse = await _ujianService.startUjian(
      pesertaUjian.pesertaUjianId,
    );

    List<QuizModel> quizList = startUjianResponse.soalList.map((soalUjian) {
      return QuizModel.fromSoalUjian(soalUjian);
    }).toList();

    return UjianModel(
      ujianId: pesertaUjian.ujian.ujianId,
      subject: namaUjian,
      grade: pesertaUjian.ujian.tingkat,
      date: DateFormatter.formatDateFromString(tanggalMulai.toString()),
      teacher: pesertaUjian.ujian.mataPelajaran,
      type: ExamTypeHelper.getExamType(namaUjian),
      ujianImage: 'assets/images/c1.jpg',
      quizList: quizList,
      pesertaUjianId: pesertaUjian.pesertaUjianId,
      durasiMenit: startUjianResponse.pesertaUjian.durasiMenit,
      waktuMulai: startUjianResponse.pesertaUjian.waktuMulai,
      tanggalSelesai: pesertaUjian.ujian.tanggalSelesai,
    );
  }

  /// Submit jawaban ujian per soal
  Future<void> submitJawaban({
    required int pesertaUjianId,
    required int soalId,
    int? opsiJawabanId,
    List<int>? opsiJawabanIds,
    String? teksJawaban,
  }) async {
    await _ujianService.submitJawaban(
      pesertaUjianId: pesertaUjianId,
      soalId: soalId,
      opsiJawabanId: opsiJawabanId,
      opsiJawabanIds: opsiJawabanIds,
      teksJawaban: teksJawaban,
    );
  }

  /// Selesaikan ujian
  Future<Map<String, dynamic>> finishUjian(int pesertaUjianId) async {
    return await _ujianService.finishUjian(pesertaUjianId);
  }

  /// Cek apakah ujian di-block (sudah pernah dikerjakan)
  Future<bool> checkBlockStatus(int ujianId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("blockKey $ujianId") ?? false;
  }

  /// Set block status untuk ujian
  Future<void> setBlockStatus(int ujianId, bool blocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("blockKey $ujianId", blocked);
  }
}

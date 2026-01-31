// Model untuk response dari API /siswa/ujians/start
class StartUjianResponseModel {
  final PesertaUjianInfo pesertaUjian;
  final List<SoalUjian> soalList;
  final int totalSoal;

  StartUjianResponseModel({
    required this.pesertaUjian,
    required this.soalList,
    required this.totalSoal,
  });

  factory StartUjianResponseModel.fromJson(Map<String, dynamic> json) {
    final pesertaUjianData = json['peserta_ujian'];
    
    return StartUjianResponseModel(
      pesertaUjian: PesertaUjianInfo.fromJson(pesertaUjianData),
      soalList: pesertaUjianData['soal_list'] != null
          ? (pesertaUjianData['soal_list'] as List)
              .map((item) => SoalUjian.fromJson(item))
              .toList()
          : [],
      totalSoal: pesertaUjianData['total_soal'] ?? 0,
    );
  }
}

class PesertaUjianInfo {
  final int pesertaUjianId;
  final String statusUjian;
  final DateTime? waktuMulai;
  final int durasiMenit;

  PesertaUjianInfo({
    required this.pesertaUjianId,
    required this.statusUjian,
    this.waktuMulai,
    required this.durasiMenit,
  });

  factory PesertaUjianInfo.fromJson(Map<String, dynamic> json) {
    return PesertaUjianInfo(
      pesertaUjianId: json['peserta_ujian_id'],
      statusUjian: json['status_ujian'],
      waktuMulai: json['waktu_mulai'] != null
          ? DateTime.parse(json['waktu_mulai'])
          : null,
      durasiMenit: json['durasi_menit'],
    );
  }
}

class SoalUjian {
  final int soalUjianId;
  final int urutan;
  final int bobotNilai;
  final Soal soal;
  final JawabanSaya? jawabanSaya;

  SoalUjian({
    required this.soalUjianId,
    required this.urutan,
    required this.bobotNilai,
    required this.soal,
    this.jawabanSaya,
  });

  factory SoalUjian.fromJson(Map<String, dynamic> json) {
    return SoalUjian(
      soalUjianId: json['soal_ujian_id'],
      urutan: json['urutan'],
      bobotNilai: json['bobot_nilai'],
      soal: Soal.fromJson(json['soal']),
      jawabanSaya: json['jawaban_saya'] != null
          ? JawabanSaya.fromJson(json['jawaban_saya'])
          : null,
    );
  }
}

class Soal {
  final int soalId;
  final String tipeSoal; // PILIHAN_GANDA_SINGLE, PILIHAN_GANDA_MULTIPLE, ESSAY
  final String teksSoal;
  final String? soalGambar;
  final List<OpsiJawaban> opsiJawaban;

  Soal({
    required this.soalId,
    required this.tipeSoal,
    required this.teksSoal,
    this.soalGambar,
    required this.opsiJawaban,
  });

  factory Soal.fromJson(Map<String, dynamic> json) {
    return Soal(
      soalId: json['soal_id'],
      tipeSoal: json['tipe_soal'],
      teksSoal: json['teks_soal'],
      soalGambar: json['soal_gambar'],
      opsiJawaban: json['opsi_jawaban'] != null
          ? (json['opsi_jawaban'] as List)
              .map((item) => OpsiJawaban.fromJson(item))
              .toList()
          : [],
    );
  }
}

class OpsiJawaban {
  final int opsiId;
  final String label;
  final String teksOpsi;

  OpsiJawaban({
    required this.opsiId,
    required this.label,
    required this.teksOpsi,
  });

  factory OpsiJawaban.fromJson(Map<String, dynamic> json) {
    return OpsiJawaban(
      opsiId: json['opsi_id'],
      label: json['label_opsi'] ?? json['label'] ?? '',
      teksOpsi: json['teks_opsi'] ?? '',
    );
  }
}

class JawabanSaya {
  final int jawabanId;
  final int? opsiJawabanId;
  final List<int>? opsiJawabanIds; // for PILIHAN_GANDA_MULTIPLE
  final String? teksJawaban;

  JawabanSaya({
    required this.jawabanId,
    this.opsiJawabanId,
    this.opsiJawabanIds,
    this.teksJawaban,
  });

  factory JawabanSaya.fromJson(Map<String, dynamic> json) {
    return JawabanSaya(
      jawabanId: json['jawaban_id'],
      opsiJawabanId: json['opsi_jawaban_id'],
      opsiJawabanIds: json['opsi_jawaban_ids'] != null
          ? List<int>.from(json['opsi_jawaban_ids'])
          : null,
      teksJawaban: json['teks_jawaban'],
    );
  }
}

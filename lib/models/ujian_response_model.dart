class UjianResponseModel {
  final List<PesertaUjian> ujians;

  UjianResponseModel({required this.ujians});

  factory UjianResponseModel.fromJson(Map<String, dynamic> json) {
    return UjianResponseModel(
      ujians: (json['ujians'] as List)
          .map((item) => PesertaUjian.fromJson(item))
          .toList(),
    );
  }
}

class PesertaUjian {
  final int pesertaUjianId;
  final String statusUjian;
  final bool isBlocked;
  final String? unlockCode;
  final DateTime? waktuMulai;
  final DateTime? waktuSelesai;
  final UjianDetail ujian;
  final HasilUjian? hasil;

  PesertaUjian({
    required this.pesertaUjianId,
    required this.statusUjian,
    required this.isBlocked,
    this.unlockCode,
    this.waktuMulai,
    this.waktuSelesai,
    required this.ujian,
    this.hasil,
  });

  factory PesertaUjian.fromJson(Map<String, dynamic> json) {
    return PesertaUjian(
      pesertaUjianId: json['peserta_ujian_id'],
      statusUjian: json['status_ujian'],
      isBlocked: json['is_blocked'],
      unlockCode: json['unlock_code'],
      waktuMulai: json['waktu_mulai'] != null 
          ? DateTime.parse(json['waktu_mulai']) 
          : null,
      waktuSelesai: json['waktu_selesai'] != null 
          ? DateTime.parse(json['waktu_selesai']) 
          : null,
      ujian: UjianDetail.fromJson(json['ujian']),
      hasil: json['hasil'] != null 
          ? HasilUjian.fromJson(json['hasil']) 
          : null,
    );
  }
}

class UjianDetail {
  final int ujianId;
  final String namaUjian;
  final String mataPelajaran;
  final String tingkat;
  final String jurusan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final int durasiMenit;
  final bool isAcakSoal;

  UjianDetail({
    required this.ujianId,
    required this.namaUjian,
    required this.mataPelajaran,
    required this.tingkat,
    required this.jurusan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.durasiMenit,
    required this.isAcakSoal,
  });

  factory UjianDetail.fromJson(Map<String, dynamic> json) {
    return UjianDetail(
      ujianId: json['ujian_id'],
      namaUjian: json['nama_ujian'],
      mataPelajaran: json['mata_pelajaran'],
      tingkat: json['tingkat'],
      jurusan: json['jurusan'],
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai']),
      durasiMenit: json['durasi_menit'],
      isAcakSoal: json['is_acak_soal'],
    );
  }
}

class HasilUjian {
  final double nilaiAkhir;
  final DateTime tanggalSubmit;

  HasilUjian({
    required this.nilaiAkhir,
    required this.tanggalSubmit,
  });

  factory HasilUjian.fromJson(Map<String, dynamic> json) {
    return HasilUjian(
      nilaiAkhir: json['nilai_akhir'].toDouble(),
      tanggalSubmit: DateTime.parse(json['tanggal_submit']),
    );
  }
}

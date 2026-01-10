class HasilUjianListResponse {
  final List<HasilEntry> hasil;

  HasilUjianListResponse({required this.hasil});

  factory HasilUjianListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['hasil'] as List? ?? [])
        .map((e) => HasilEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return HasilUjianListResponse(hasil: list);
  }
}

class HasilEntry {
  final int hasilUjianId;
  final int pesertaUjianId;
  final double nilaiAkhir;
  final DateTime tanggalSubmit;
  final PesertaUjianHasil pesertaUjian;

  HasilEntry({
    required this.hasilUjianId,
    required this.pesertaUjianId,
    required this.nilaiAkhir,
    required this.tanggalSubmit,
    required this.pesertaUjian,
  });

  factory HasilEntry.fromJson(Map<String, dynamic> json) {
    return HasilEntry(
      hasilUjianId: json['hasil_ujian_id'] as int? ?? 0,
      pesertaUjianId: json['peserta_ujian_id'] as int? ?? 0,
      nilaiAkhir: (json['nilai_akhir'] as num?)?.toDouble() ?? 0.0,
      tanggalSubmit: json['tanggal_submit'] != null
          ? DateTime.parse(json['tanggal_submit'] as String)
          : DateTime.now(),
      pesertaUjian: PesertaUjianHasil.fromJson(
        (json['peserta_ujians'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class PesertaUjianHasil {
  final int pesertaUjianId;
  final int siswaId;
  final int ujianId;
  final String statusUjian;
  final UjianShort ujian;

  PesertaUjianHasil({
    required this.pesertaUjianId,
    required this.siswaId,
    required this.ujianId,
    required this.statusUjian,
    required this.ujian,
  });

  factory PesertaUjianHasil.fromJson(Map<String, dynamic> json) {
    return PesertaUjianHasil(
      pesertaUjianId: json['peserta_ujian_id'] as int? ?? 0,
      siswaId: json['siswa_id'] as int? ?? 0,
      ujianId: json['ujian_id'] as int? ?? 0,
      statusUjian: json['status_ujian'] as String? ?? '',
      ujian: UjianShort.fromJson(
        (json['ujians'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class UjianShort {
  final int ujianId;
  final String namaUjian;
  final String mataPelajaran;
  final String tingkat;
  final String jurusan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;

  UjianShort({
    required this.ujianId,
    required this.namaUjian,
    required this.mataPelajaran,
    required this.tingkat,
    required this.jurusan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
  });

  factory UjianShort.fromJson(Map<String, dynamic> json) {
    return UjianShort(
      ujianId: json['ujian_id'] as int? ?? 0,
      namaUjian: json['nama_ujian'] as String? ?? '',
      mataPelajaran: json['mata_pelajaran'] as String? ?? '',
      tingkat: json['tingkat'] as String? ?? '',
      jurusan: json['jurusan'] as String? ?? '',
      tanggalMulai: json['tanggal_mulai'] != null
          ? DateTime.parse(json['tanggal_mulai'] as String)
          : DateTime.now(),
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.parse(json['tanggal_selesai'] as String)
          : DateTime.now(),
    );
  }
}

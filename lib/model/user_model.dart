class UserModel {
  int? id;
  int siswa_id;
  String nama_lengkap;
  String kelas;
  String tingkat;
  String jurusan;

  UserModel({
    this.id,
    required this.siswa_id, 
    required this.nama_lengkap,
    required this.kelas,
    required this.tingkat,
    required this.jurusan
  });

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      id: json['id'],
      siswa_id: json['profile']['siswa_id'], 
      nama_lengkap: json['profile']['nama_lengkap'], 
      kelas: json['profile']['kelas'], 
      tingkat: json['profile']['tingkat'], 
      jurusan: json['profile']['jurusan'], );}
}
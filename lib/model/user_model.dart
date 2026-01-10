// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
    String message;
    String token;
    User user;

    UserModel({
        required this.message,
        required this.token,
        required this.user,
    });

    factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        message: json["message"],
        token: json["token"],
        user: User.fromJson(json["user"]),
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "token": token,
        "user": user.toJson(),
    };
}

class User {
    int id;
    String role;
    Profile profile;

    User({
        required this.id,
        required this.role,
        required this.profile,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        role: json["role"],
        profile: Profile.fromJson(json["profile"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "role": role,
        "profile": profile.toJson(),
    };
}

class Profile {
    int siswaId;
    String namaLengkap;
    String kelas;
    String tingkat;
    String jurusan;
    int userId;

    Profile({
        required this.siswaId,
        required this.namaLengkap,
        required this.kelas,
        required this.tingkat,
        required this.jurusan,
        required this.userId,
    });

    factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        siswaId: json["siswa_id"],
        namaLengkap: json["nama_lengkap"],
        kelas: json["kelas"],
        tingkat: json["tingkat"],
        jurusan: json["jurusan"],
        userId: json["userId"],
    );

    Map<String, dynamic> toJson() => {
        "siswa_id": siswaId,
        "nama_lengkap": namaLengkap,
        "kelas": kelas,
        "tingkat": tingkat,
        "jurusan": jurusan,
        "userId": userId,
    };
}

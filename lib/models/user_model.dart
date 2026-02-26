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
        message: json["message"] as String? ?? '',
        token: json["token"] as String? ?? '',
        user: User.fromJson((json["user"] as Map<String, dynamic>?) ?? {}),
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
        id: json["id"] as int? ?? 0,
        role: json["role"] as String? ?? '',
        profile: Profile.fromJson((json["profile"] as Map<String, dynamic>?) ?? {}),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "role": role,
        "profile": profile.toJson(),
    };
}

class Profile {
    int? studentId;
    int? teacherId;
    int? adminId;
    String fullName;
    String? nisn;
    String? nip;
    String? classroom;
    String? gradeLevel;
    String? major;
    int? userId;

    Profile({
        this.studentId,
        this.teacherId,
        this.adminId,
        required this.fullName,
        this.nisn,
        this.nip,
        this.classroom,
        this.gradeLevel,
        this.major,
        this.userId,
    });

    factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        studentId: json["student_id"] as int?,
        teacherId: json["teacher_id"] as int?,
        adminId: json["admin_id"] as int?,
        fullName: json["full_name"] as String? ?? '',
        nisn: json["nisn"] as String?,
        nip: json["nip"] as String?,
        classroom: json["classroom"] as String?,
        gradeLevel: json["grade_level"] as String?,
        major: json["major"] as String?,
        userId: json["user_id"] as int?,
    );

    Map<String, dynamic> toJson() => {
        if (studentId != null) "student_id": studentId,
        if (teacherId != null) "teacher_id": teacherId,
        if (adminId != null) "admin_id": adminId,
        "full_name": fullName,
        if (nisn != null) "nisn": nisn,
        if (nip != null) "nip": nip,
        if (classroom != null) "classroom": classroom,
        if (gradeLevel != null) "grade_level": gradeLevel,
        if (major != null) "major": major,
        if (userId != null) "user_id": userId,
    };
}

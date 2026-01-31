import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cbt_app/models/user_model.dart';
import 'package:cbt_app/services/profile_service.dart';
import 'package:cbt_app/utils/session_manager.dart';

class ProfileController {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  /// Mengambil data profile dari server
  Future<UserModel> fetchProfile() async {
    return await _profileService.fetchProfile();
  }

  /// Update profile ke server
  Future<UserModel> updateProfile({
    required String namaLengkap,
    required String role,
    String? kelas,
    String? jurusan,
    String? tingkat,
  }) async {
    return await _profileService.updateProfile(
      namaLengkap: namaLengkap,
      role: role,
      kelas: kelas,
      jurusan: jurusan,
      tingkat: tingkat,
    );
  }

  /// Mengambil gambar profile yang tersimpan di local
  Future<String?> getProfileImage() async {
    return await SessionManager.getProfileImage();
  }

  /// Menyimpan gambar profile ke local storage
  Future<void> saveProfileImage(String base64Image) async {
    await SessionManager.setProfileImage(base64Image);
  }

  /// Pick image dari gallery atau camera, return base64 string
  Future<String?> pickAndSaveImage(ImageSource source) async {
    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);

    await saveProfileImage(base64Image);
    return base64Image;
  }

  /// Decode base64 image untuk ditampilkan
  List<int>? decodeProfileImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      return base64Decode(base64Image);
    } catch (e) {
      return null;
    }
  }
}

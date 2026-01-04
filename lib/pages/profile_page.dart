import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../style/style.dart';
import '../utlis/session_manager.dart';
import '../services/ProfileService.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _tingkatController = TextEditingController();
  final TextEditingController _jurusanController = TextEditingController();
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  final ProfileService _profileService = ProfileService();

  Future<void> _loadProfile() async {
    // Load only the profile image from SharedPreferences
    final profileImage = await SessionManager.getProfileImage();

    // Set some sensible defaults for textual fields
    setState(() {
      _nameController.text = 'Sidqi Ramadhan';
      _roleController.text = 'Siswa';
      _kelasController.text = '9B';
      _tingkatController.text = 'X';
      _jurusanController.text = 'IPA';
      _profileImageBase64 = profileImage;
    });

    // Try to fetch profile from server (do not persist it locally)
    try {
      final userModel = await _profileService.fetchProfile();
      setState(() {
        _nameController.text = userModel.user.profile.namaLengkap;
        _roleController.text = userModel.user.role;
        _kelasController.text = userModel.user.profile.kelas;
        _tingkatController.text = userModel.user.profile.tingkat;
        _jurusanController.text = userModel.user.profile.jurusan;
      });
    } catch (e) {
      // Not fatal; keep defaults and profile image from SharedPreferences
    }
  }

  // pick image from specified source and save as base64 to SharedPreferences
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      await SessionManager.setProfileImage(base64Image);

      setState(() {
        _profileImageBase64 = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show bottom sheet to choose camera or gallery (and an option to remove photo)
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Hapus Foto'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await SessionManager.setProfileImage('');
                  setState(() {
                    _profileImageBase64 = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper to show label + big value style used inside the card
  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _kelasController.dispose();
    _tingkatController.dispose();
    _jurusanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarImage =
        (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty)
        ? MemoryImage(base64Decode(_profileImageBase64!))
        : const AssetImage('assets/images/profile.png');

    return Scaffold(
      backgroundColor: ColorsApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.backgroundColor,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Stacked layout: avatar overlaps a rounded card with profile details (wider for emulator)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Card with profile fields, taking most of the screen width
                    Container(
                      width: MediaQuery.of(context).size.width * 0.94,
                      margin: const EdgeInsets.only(top: 100),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 120, 18, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _labelValue('Nama', _nameController.text),
                              const SizedBox(height: 14),
                              _labelValue('Role', _roleController.text),
                              const SizedBox(height: 14),
                              _labelValue('Kelas', _kelasController.text),
                              const SizedBox(height: 14),
                              _labelValue('Jurusan', _jurusanController.text),
                              const SizedBox(height: 14),
                              _labelValue('Tingkat', _tingkatController.text),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Centered avatar that overlaps the card; increased size for better visibility
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 200,
                        height: 200,
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 100,
                              backgroundImage: avatarImage,
                            ),

                            // Camera floating button
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _showImageSourceActionSheet,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C6FF), // cyan-ish
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

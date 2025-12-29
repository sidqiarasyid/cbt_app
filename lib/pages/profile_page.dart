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
            padding: const EdgeInsets.all(35.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // avatar with pick button
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(radius: 75, backgroundImage: avatarImage),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceActionSheet,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          padding: const EdgeInsets.all(8),
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
                const SizedBox(height: 30),

                ListTile(
                  title: const Text(
                    'Nama Lengkap',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  subtitle: Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  title: const Text(
                    'Role',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  subtitle: Text(
                    _roleController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  title: const Text(
                    'Kelas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  subtitle: Text(
                    _kelasController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  title: const Text(
                    'Jurusan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  subtitle: Text(
                    _jurusanController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  title: const Text(
                    'Tingkat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  subtitle: Text(
                    _tingkatController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

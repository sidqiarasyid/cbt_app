import 'dart:convert';
import 'package:cbt_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final profileImage = await SessionManager.getProfileImage();

    setState(() {
      _nameController.text = 'Sidqi Ramadhan';
      _roleController.text = 'Siswa';
      _kelasController.text = '9B';
      _tingkatController.text = 'X';
      _jurusanController.text = 'IPA';
      _profileImageBase64 = profileImage;
    });
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
      //
    }
  }

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

  Future<void> logout() async{
  SharedPreferences myPref = await SharedPreferences.getInstance();  
  showDialog(context: context, builder: (BuildContext context) {
    return  Dialog(  
      backgroundColor: Colors.transparent,
      elevation: 0.0, 
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_outlined, size: 40, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              "Apakah anda yakin ingin keluar",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Batal",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF11B1E2).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async{
                        await myPref.remove('token');
                        Navigator.push(context, (MaterialPageRoute(builder: (context) => Loginpage(),)));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Keluar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  });
 
  }

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
        actions: [
          IconButton(onPressed: (){
            logout();
          }, icon: Icon(Icons.logout_outlined, size: 30,))
        ],
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



import 'package:cbt_app/controllers/auth_controller.dart';
import 'package:cbt_app/views/login_page.dart';
import 'package:cbt_app/widgets/dialogs/logout_dialog.dart';
import 'package:cbt_app/widgets/dialogs/change_password_dialog.dart';
import 'package:flutter/material.dart';

import '../style/style.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _classroomController = TextEditingController();
  final TextEditingController _gradeLevelController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _nisnController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  final ProfileService _profileService = ProfileService();

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _nameController.text = '';
      _roleController.text = '';
      _classroomController.text = '';
      _gradeLevelController.text = '';
      _majorController.text = '';
    });
    try {
      final userModel = await _profileService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = userModel.user.profile.fullName;
        _roleController.text = userModel.user.role;
        _classroomController.text = userModel.user.profile.classroom ?? '';
        _gradeLevelController.text = userModel.user.profile.gradeLevel ?? '';
        _majorController.text = userModel.user.profile.major ?? '';
        _nisnController.text = userModel.user.profile.nisn ?? '';
        _nipController.text = userModel.user.profile.nip ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat profil. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final AuthController _authController = AuthController();

  Future<void> logout() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LogoutDialog(
          onConfirmLogout: () async {
            await _authController.logout();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Loginpage()),
              (route) => false,
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ChangePasswordDialog(
          onSuccess: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password berhasil diubah'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _classroomController.dispose();
    _gradeLevelController.dispose();
    _majorController.dispose();
    _nisnController.dispose();
    _nipController.dispose();
    super.dispose();
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF11B1E2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF11B1E2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build initials from name
    final name = _nameController.text;
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words.isNotEmpty
        ? words.map((w) => w[0]).join('').toUpperCase().substring(0, words.length >= 2 ? 2 : 1)
        : '?';

    return Scaffold(
      backgroundColor: ColorsApp.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient header with avatar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                ),
              ),
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => logout(),
                          icon: const Icon(Icons.logout_outlined, size: 26, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF11B1E2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : '...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _roleController.text.isNotEmpty ? _roleController.text : '...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Profile details card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Siswa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Divider(height: 16),
                        if (_nisnController.text.isNotEmpty)
                          _buildProfileRow(Icons.badge_outlined, 'NISN', _nisnController.text),
                        if (_nipController.text.isNotEmpty)
                          _buildProfileRow(Icons.badge_outlined, 'NIP', _nipController.text),
                        _buildProfileRow(Icons.class_outlined, 'Kelas', _classroomController.text),
                        _buildProfileRow(Icons.school_outlined, 'Jurusan', _majorController.text),
                        _buildProfileRow(Icons.layers_outlined, 'Tingkat', _gradeLevelController.text),
                        const Spacer(),
                        // Change password button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF11B1E2).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _showChangePasswordDialog,
                              icon: const Icon(Icons.lock_outline, color: Colors.white),
                              label: const Text(
                                'Ubah Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

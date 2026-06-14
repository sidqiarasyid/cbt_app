import 'package:cbt_app/providers/auth_provider.dart';
import 'package:cbt_app/views/login_page.dart';
import 'package:cbt_app/widgets/dialogs/logout_dialog.dart';
import 'package:cbt_app/widgets/dialogs/change_password_dialog.dart';
import 'package:cbt_app/services/school_profile_service.dart';
import 'package:cbt_app/models/school_profile_model.dart';
import 'package:cbt_app/config/env.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/style.dart';
import '../services/profile_service.dart';
import '../utils/page_transitions.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _primary = Color(0xFF11B1E2);
  static const Color _primaryDark = Color(0xFF0E8FB5);

  final ProfileService _profileService = ProfileService();

  String _fullName = '';
  String _role = '';
  String _classroom = '';
  String _gradeLevel = '';
  String _major = '';
  String _nisn = '';
  String _nip = '';

  String? _schoolName;
  String? _schoolLogoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _profileService.fetchProfile(),
      SchoolProfileService.fetchProfile(),
    ]);
    if (!mounted) return;
    try {
      final userModel = results[0] as dynamic;
      final school = results[1] as SchoolProfileModel;
      setState(() {
        _fullName = userModel.user.profile.fullName ?? '';
        _role = userModel.user.role ?? '';
        _classroom = userModel.user.profile.classroom ?? '';
        _gradeLevel = userModel.user.profile.gradeLevel ?? '';
        _major = userModel.user.profile.major ?? '';
        _nisn = userModel.user.profile.nisn ?? '';
        _nip = userModel.user.profile.nip ?? '';
        _schoolName = school.schoolName;
        _schoolLogoUrl = Env.resolveAssetUrl(school.logoUrl);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat profil. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return LogoutDialog(
          onConfirmLogout: () async {
            await auth.logout();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              fadeSlideRoute(const LoginPage()),
              (route) => false,
            );
          },
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    ChangePasswordSheet.show(
      context,
      onSuccess: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  String get _initials {
    final words = _fullName.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final letters = words.map((w) => w[0]).join().toUpperCase();
    return letters.substring(0, letters.length >= 2 ? 2 : 1);
  }

  String get _subtitle {
    final parts = <String>[];
    if (_schoolName != null && _schoolName!.isNotEmpty) parts.add(_schoolName!);
    if (_classroom.isNotEmpty) parts.add(_classroom);
    return parts.join(' • ');
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : RefreshIndicator(
                color: _primary,
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _topBar(),
                    const SizedBox(height: 16),
                    _heroCard(),
                    const SizedBox(height: 20),
                    _sectionLabel('Informasi'),
                    const SizedBox(height: 8),
                    _infoCard(),
                    const SizedBox(height: 20),
                    _sectionLabel('Akun'),
                    const SizedBox(height: 8),
                    _accountCard(),
                  ],
                ),
              ),
      ),
    );
  }

  // ---- Top bar --------------------------------------------------------------
  Widget _topBar() {
    return Row(
      children: [
        if (_schoolLogoUrl != null)
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                _schoolLogoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.school, color: _primary, size: 20),
              ),
            ),
          )
        else
          const Icon(Icons.school_rounded, color: _primary, size: 28),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Profil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // ---- Hero card (avatar + name + subtitle) --------------------------------
  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar - ring + circle with initials
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _fullName.isNotEmpty ? _fullName : '-',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (_role.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Section label --------------------------------------------------------
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // ---- Info card ------------------------------------------------------------
  Widget _infoCard() {
    final rows = <Widget>[];
    void addRow(IconData icon, String label, String value) {
      if (value.isEmpty) return;
      if (rows.isNotEmpty) rows.add(const Divider(height: 1, indent: 56));
      rows.add(_infoRow(icon, label, value));
    }

    if (_nisn.isNotEmpty) addRow(Icons.badge_outlined, 'NISN', _nisn);
    if (_nip.isNotEmpty) addRow(Icons.badge_outlined, 'NIP', _nip);
    addRow(Icons.class_outlined, 'Kelas', _classroom);
    addRow(Icons.layers_outlined, 'Tingkat', _gradeLevel);
    addRow(Icons.school_outlined, 'Jurusan', _major);

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'Belum ada data',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _primary),
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
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
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

  // ---- Account card (change password + logout) -----------------------------
  Widget _accountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _actionRow(
            icon: Icons.lock_outline,
            iconColor: _primary,
            iconBg: _primary.withValues(alpha: 0.1),
            label: 'Ubah Password',
            subtitle: 'Perbarui password akun Anda',
            onTap: _showChangePasswordSheet,
          ),
          const Divider(height: 1, indent: 56),
          _actionRow(
            icon: Icons.logout,
            iconColor: Colors.red.shade600,
            iconBg: Colors.red.withValues(alpha: 0.1),
            label: 'Keluar',
            subtitle: 'Akhiri sesi dan kembali ke login',
            labelColor: Colors.red.shade600,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

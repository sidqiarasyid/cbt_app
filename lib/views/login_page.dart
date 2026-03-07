import 'package:cbt_app/controllers/auth_controller.dart';
import 'package:cbt_app/services/school_profile_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  final AuthController _authController = AuthController();
  String _schoolName = 'CBT App';

  static const Color _primaryBlue = Color(0xFF11B1E2);

  @override
  void initState() {
    super.initState();
    _loadSchoolProfile();
  }

  Future<void> _loadSchoolProfile() async {
    final profile = await SchoolProfileService.fetchProfile();
    if (mounted) {
      setState(() => _schoolName = profile.schoolName);
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (userController.text.trim().isEmpty || passController.text.isEmpty) {
      _showError('Username dan password tidak boleh kosong');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authController.login(
          userController.text.trim(), passController.text);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Solid blue background ──
          Container(color: _primaryBlue),

          // ── Decorative circles ──
          Positioned(
            top: -60,
            right: -40,
            child: _decorativeCircle(180, const Color(0x14FFFFFF)),
          ),
          Positioned(
            top: 80,
            left: -50,
            child: _decorativeCircle(120, const Color(0x0FFFFFFF)),
          ),

          // ── Bottom white wave ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _BottomWaveClipper(),
              child: Container(
                height: size.height * 0.58,
                color: Colors.white,
              ),
            ),
          ),

          // ── Second wave (subtle) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _BottomWaveClipper2(),
              child: Container(
                height: size.height * 0.58,
                color: const Color(0x66FFFFFF),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Static header area (blue zone) ──
                SizedBox(height: size.height * 0.15),
                // Logo / school icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0x33FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x4DFFFFFF), width: 2),
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/sekolah.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _schoolName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign into your Account',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xE6FFFFFF),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                // ── Scrollable form area ──
                SizedBox(height: size.height * 0.10),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // Username field
                          _buildTextField(
                            controller: userController,
                            hint: 'Username',
                            icon: Icons.person_outline_rounded,
                            maxLength: 50,
                          ),
                          const SizedBox(height: 18),
                          // Password field
                          _buildTextField(
                            controller: passController,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            maxLength: 128,
                            isPassword: true,
                          ),
                          const SizedBox(height: 32),
                          // Login button
                          _buildLoginButton(),
                          const SizedBox(height: 40),
                          // Footer
                          Text(
                            'CBT Exam System',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading overlay ──
          if (isLoading)
            Container(
              color: const Color(0x4D000000),
              child: const Center(
                child: CircularProgressIndicator(
                  color: _primaryBlue,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLength = 50,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        obscuringCharacter: '•',
        maxLength: maxLength,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          counterText: '',
          prefixIcon: Icon(icon, color: _primaryBlue, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.grey[400],
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _primaryBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x5911B1E2),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: isLoading ? null : () => login(),
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Wave Clippers ──

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 80);

    path.quadraticBezierTo(
      size.width * 0.25, 0,
      size.width * 0.5, 40,
    );
    path.quadraticBezierTo(
      size.width * 0.75, 80,
      size.width, 30,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomWaveClipper2 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 50);

    path.quadraticBezierTo(
      size.width * 0.3, 100,
      size.width * 0.55, 55,
    );
    path.quadraticBezierTo(
      size.width * 0.8, 10,
      size.width, 60,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

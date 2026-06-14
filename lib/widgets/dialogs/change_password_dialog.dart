import 'package:flutter/material.dart';
import 'package:cbt_app/services/profile_service.dart';

/// Bottom sheet for changing the user's password.
///
/// Provides real-time strength scoring and a requirement checklist so the
/// student knows whether their new password is acceptable *before* hitting
/// submit. Designed as a draggable bottom sheet so the keyboard doesn't
/// obscure the submit button on small screens.
///
/// Usage:
///   ChangePasswordSheet.show(context, onSuccess: () { ... });
class ChangePasswordSheet extends StatefulWidget {
  /// Called after the password is successfully changed (sheet auto-closes).
  final VoidCallback? onSuccess;

  const ChangePasswordSheet({super.key, this.onSuccess});

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => ChangePasswordSheet(onSuccess: onSuccess),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  static const Color _primary = Color(0xFF11B1E2);
  static const Color _primaryDark = Color(0xFF0E8FB5);

  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _newPw = '';
  String _confirmPw = '';

  @override
  void initState() {
    super.initState();
    _newPwController.addListener(() {
      if (_newPwController.text != _newPw) {
        setState(() => _newPw = _newPwController.text);
      }
    });
    _confirmPwController.addListener(() {
      if (_confirmPwController.text != _confirmPw) {
        setState(() => _confirmPw = _confirmPwController.text);
      }
    });
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // ---- Strength scoring -----------------------------------------------------
  // Score is 0..4, used to pick a label/colour and fill the meter.
  int get _strength {
    final pw = _newPw;
    if (pw.isEmpty) return 0;
    var score = 0;
    if (pw.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(pw)) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
        return '';
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Kuat';
      default:
        return 'Sangat Kuat';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 0:
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.lightGreen;
      default:
        return Colors.green;
    }
  }

  // ---- Submit ---------------------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _profileService.changePassword(
        currentPassword: _currentPwController.text,
        newPassword: _newPwController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess?.call();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---- UI -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_outline, color: _primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ubah Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.black45),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current password
                  _passwordField(
                    controller: _currentPwController,
                    label: 'Password Saat Ini',
                    obscure: _obscureCurrent,
                    onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // New password
                  _passwordField(
                    controller: _newPwController,
                    label: 'Password Baru',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (v.length < 8) return 'Minimal 8 karakter';
                      return null;
                    },
                  ),
                  if (_newPw.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _strengthMeter(),
                    const SizedBox(height: 10),
                    _requirementsList(),
                  ],
                  const SizedBox(height: 14),

                  // Confirm password
                  _passwordField(
                    controller: _confirmPwController,
                    label: 'Konfirmasi Password Baru',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    suffixHint: _confirmPw.isNotEmpty
                        ? (_confirmPw == _newPw
                            ? const _MatchHint(matched: true)
                            : const _MatchHint(matched: false))
                        : null,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (v != _newPwController.text) return 'Password tidak cocok';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  // Submit
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primary, _primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Sub-widgets ----------------------------------------------------------
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    Widget? suffixHint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suffixHint != null) Padding(padding: const EdgeInsets.only(right: 4), child: suffixHint),
            IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: onToggle,
              color: Colors.grey,
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _strengthMeter() {
    final fillRatio = _strength / 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < _strength;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? _strengthColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Kekuatan: $_strengthLabel',
          style: TextStyle(
            fontSize: 11,
            color: fillRatio > 0 ? _strengthColor : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _requirementsList() {
    final pw = _newPw;
    final checks = [
      ('Minimal 8 karakter', pw.length >= 8),
      ('Mengandung huruf besar', RegExp(r'[A-Z]').hasMatch(pw)),
      ('Mengandung angka', RegExp(r'[0-9]').hasMatch(pw)),
      ('Mengandung simbol', RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(pw)),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: checks.map((c) {
          final met = c.$2;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  met ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 14,
                  color: met ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  c.$1,
                  style: TextStyle(
                    fontSize: 11,
                    color: met ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: met ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MatchHint extends StatelessWidget {
  final bool matched;
  const _MatchHint({required this.matched});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: matched ? 'Cocok' : 'Belum cocok',
      child: Icon(
        matched ? Icons.check_circle : Icons.cancel,
        color: matched ? Colors.green : Colors.redAccent,
        size: 18,
      ),
    );
  }
}

// Backwards-compatible alias - existing callers using `ChangePasswordDialog`
// continue to work via this re-export.
typedef ChangePasswordDialog = ChangePasswordSheet;

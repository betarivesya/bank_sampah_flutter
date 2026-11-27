import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class PengaturanAkunScreen extends StatefulWidget {
  final String currentEmail;

  const PengaturanAkunScreen({super.key, this.currentEmail = ''});

  @override
  State<PengaturanAkunScreen> createState() => _PengaturanAkunScreenState();
}

class _PengaturanAkunScreenState extends State<PengaturanAkunScreen> {
  static const Color darkGreen = Color(0xFF123D36);
  static const Color primaryGreen = Color(0xFF065F46);

  final _emailBaruController = TextEditingController();
  final _passwordEmailController = TextEditingController();

  final _passwordSaatIniController = TextEditingController();
  final _passwordBaruController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();

  late String _currentEmail;

  bool _obscurePasswordEmail = true;
  bool _obscurePasswordSaatIni = true;
  bool _obscurePasswordBaru = true;
  bool _obscureKonfirmasi = true;

  bool _isSavingEmail = false;
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.currentEmail.isNotEmpty
        ? widget.currentEmail
        : ApiService.currentUserEmail;
  }

  @override
  void dispose() {
    _emailBaruController.dispose();
    _passwordEmailController.dispose();
    _passwordSaatIniController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? primaryGreen : Colors.red.shade700,
        ),
      );
  }

  // ==========================================================
  // SIMPAN EMAIL
  // ==========================================================

  Future<void> _simpanEmail() async {
    final emailBaru = _emailBaruController.text.trim();
    final password = _passwordEmailController.text;

    if (emailBaru.isEmpty || password.isEmpty) {
      _showMessage('Email baru dan password saat ini wajib diisi.');
      return;
    }

    final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(emailBaru);

    if (!emailValid) {
      _showMessage('Format email tidak valid.');
      return;
    }

    if (emailBaru.toLowerCase() == _currentEmail.toLowerCase()) {
      _showMessage('Email baru sama dengan email saat ini.');
      return;
    }

    setState(() => _isSavingEmail = true);

    try {
      final result = await ApiService.updateSuperadminEmail(
        email: emailBaru,
        currentPassword: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _currentEmail = result['user']?['email']?.toString() ?? emailBaru;
        });

        _emailBaruController.clear();
        _passwordEmailController.clear();

        _showMessage(
          result['message'] ?? 'Email berhasil diperbarui.',
          success: true,
        );
      } else {
        _showMessage(result['message'] ?? 'Gagal memperbarui email.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingEmail = false);
      }
    }
  }

  // ==========================================================
  // SIMPAN PASSWORD
  // ==========================================================

  Future<void> _simpanPassword() async {
    final passwordSaatIni = _passwordSaatIniController.text;
    final passwordBaru = _passwordBaruController.text;
    final konfirmasi = _konfirmasiPasswordController.text;

    if (passwordSaatIni.isEmpty || passwordBaru.isEmpty || konfirmasi.isEmpty) {
      _showMessage('Semua kolom password wajib diisi.');
      return;
    }

    if (passwordBaru.length < 8) {
      _showMessage('Password baru minimal 8 karakter.');
      return;
    }

    if (passwordBaru != konfirmasi) {
      _showMessage('Konfirmasi password baru tidak sama.');
      return;
    }

    if (passwordSaatIni == passwordBaru) {
      _showMessage('Password baru tidak boleh sama dengan password saat ini.');
      return;
    }

    setState(() => _isSavingPassword = true);

    try {
      final result = await ApiService.updateSuperadminPassword(
        currentPassword: passwordSaatIni,
        newPassword: passwordBaru,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _passwordSaatIniController.clear();
        _passwordBaruController.clear();
        _konfirmasiPasswordController.clear();

        _showMessage(
          result['message'] ?? 'Password berhasil diperbarui.',
          success: true,
        );
      } else {
        _showMessage(result['message'] ?? 'Gagal memperbarui password.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengaturan Akun',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Kelola email dan password akun Superadmin Anda.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 22),

              // BAGIAN UBAH EMAIL
              _buildCard(
                icon: Icons.email_outlined,
                title: 'Ubah Email',
                subtitle: 'Perbarui alamat email akun Anda.',
                children: [
                  _buildReadOnlyField(
                    label: 'Email Saat Ini',
                    value: _currentEmail.isEmpty
                        ? 'Email belum tersedia'
                        : _currentEmail,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    controller: _emailBaruController,
                    label: 'Email Baru',
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    controller: _passwordEmailController,
                    label: 'Password Saat Ini',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePasswordEmail,
                    suffix: _visibilityButton(
                      _obscurePasswordEmail,
                      () => setState(() {
                        _obscurePasswordEmail = !_obscurePasswordEmail;
                      }),
                    ),
                  ),
                  const SizedBox(height: 22),

                  _buildButton(
                    label: 'Simpan Email',
                    loading: _isSavingEmail,
                    onPressed: _simpanEmail,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // BAGIAN UBAH PASSWORD
              _buildCard(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
                subtitle: 'Pastikan password baru Anda aman.',
                children: [
                  _buildField(
                    controller: _passwordSaatIniController,
                    label: 'Password Saat Ini',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePasswordSaatIni,
                    suffix: _visibilityButton(
                      _obscurePasswordSaatIni,
                      () => setState(() {
                        _obscurePasswordSaatIni = !_obscurePasswordSaatIni;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    controller: _passwordBaruController,
                    label: 'Password Baru',
                    icon: Icons.lock_reset_outlined,
                    obscureText: _obscurePasswordBaru,
                    suffix: _visibilityButton(
                      _obscurePasswordBaru,
                      () => setState(() {
                        _obscurePasswordBaru = !_obscurePasswordBaru;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    controller: _konfirmasiPasswordController,
                    label: 'Konfirmasi Password Baru',
                    icon: Icons.lock_outline,
                    obscureText: _obscureKonfirmasi,
                    suffix: _visibilityButton(
                      _obscureKonfirmasi,
                      () => setState(() {
                        _obscureKonfirmasi = !_obscureKonfirmasi;
                      }),
                    ),
                  ),
                  const SizedBox(height: 22),

                  _buildButton(
                    label: 'Simpan Password',
                    loading: _isSavingPassword,
                    onPressed: _simpanPassword,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryGreen, size: 22),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      key: ValueKey(value),
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: !obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  Widget _visibilityButton(bool obscure, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(loading ? 'Menyimpan...' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

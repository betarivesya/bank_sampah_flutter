import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class PetugasProfileScreen extends StatefulWidget {
  final int idPetugas;

  const PetugasProfileScreen({super.key, required this.idPetugas});

  @override
  State<PetugasProfileScreen> createState() => _PetugasProfileScreenState();
}

class _PetugasProfileScreenState extends State<PetugasProfileScreen> {
  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF16866D);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF71847F);

  final _emailBaruController = TextEditingController();
  final _passwordEmailController = TextEditingController();

  final _passwordSaatIniController = TextEditingController();
  final _passwordBaruController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();

  Map<String, dynamic>? _profil;

  bool _isLoading = true;
  bool _isSavingEmail = false;
  bool _isSavingPassword = false;

  bool _obscurePasswordEmail = true;
  bool _obscurePasswordSaatIni = true;
  bool _obscurePasswordBaru = true;
  bool _obscureKonfirmasi = true;

  String get _currentEmail => _profil?['email']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfil();
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

  // ==========================================================
  // AMBIL PROFIL PETUGAS
  // ==========================================================

  Future<void> _loadProfil() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getProfilPetugas();

      if (!mounted) return;

      if (result['success'] == true && result['data'] is Map) {
        setState(() {
          _profil = Map<String, dynamic>.from(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showMessage(result['message'] ?? 'Gagal mengambil data profil.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Terjadi kesalahan saat mengambil profil.');
    }
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
      final result = await ApiService.updatePetugasEmail(
        email: emailBaru,
        currentPassword: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final updatedEmail =
            result['data']?['email']?.toString() ??
            result['user']?['email']?.toString() ??
            emailBaru;

        setState(() {
          _profil = {...?_profil, 'email': updatedEmail};
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
    } catch (e) {
      if (!mounted) return;
      _showMessage('Terjadi kesalahan saat memperbarui email.');
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
    final konfirmasi = _konfirmasiPasswordController.text.trim();

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
      final result = await ApiService.updatePetugasPassword(
        currentPassword: passwordSaatIni,
        newPassword: passwordBaru,
        newPasswordConfirmation: konfirmasi,
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
    } catch (e) {
      if (!mounted) return;
      _showMessage('Terjadi kesalahan saat memperbarui password.');
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? darkGreen : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ==========================================================
  // HEADER PROFIL
  // ==========================================================

  Widget _buildProfileHeader() {
    final nama = _profil?['nama_lengkap']?.toString() ?? 'Petugas';

    final id =
        _profil?['id_pengguna_petugas']?.toString() ??
        widget.idPetugas.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 49,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'PETUGAS  •  ID $id',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMASI PRIBADI
  // ==========================================================

  Widget _profileInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEEB)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: darkGreen, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: textGrey),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CARD PENGATURAN
  // ==========================================================

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
        border: Border.all(color: const Color(0xFFE8EEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryGreen, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ==========================================================
  // READ ONLY FIELD
  // ==========================================================

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      key: ValueKey(value),
      initialValue: value.isEmpty ? 'Email belum tersedia' : value,
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

  // ==========================================================
  // INPUT FIELD
  // ==========================================================

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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFDDE5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  // ==========================================================
  // TOMBOL LIHAT / SEMBUNYIKAN PASSWORD
  // ==========================================================

  Widget _visibilityButton(bool obscure, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }

  // ==========================================================
  // TOMBOL SIMPAN
  // ==========================================================

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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: darkGreen,
      onRefresh: _loadProfil,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: _isLoading
            ? const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(color: darkGreen),
                ),
              )
            : _profil == null
            ? _buildErrorState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil Saya',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola informasi dan keamanan akun petugas Anda.',
                    style: TextStyle(fontSize: 13, color: textGrey),
                  ),
                  const SizedBox(height: 20),

                  _buildProfileHeader(),

                  const SizedBox(height: 25),

                  const Text(
                    'Informasi Pribadi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _profileInfo(
                    icon: Icons.person_outline,
                    label: 'Nama Lengkap',
                    value: _profil!['nama_lengkap']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),

                  _profileInfo(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _currentEmail,
                  ),
                  const SizedBox(height: 12),

                  _profileInfo(
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon',
                    value: _profil!['no_telepon']?.toString() ?? '-',
                  ),

                  const SizedBox(height: 25),

                  // ========================================
                  // UBAH EMAIL
                  // ========================================
                  _buildCard(
                    icon: Icons.email_outlined,
                    title: 'Ubah Email',
                    subtitle: 'Perbarui alamat email yang digunakan untuk masuk ke akun.',
                    children: [
                      _buildReadOnlyField(
                        label: 'Email Saat Ini',
                        value: _currentEmail,
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

                  // ========================================
                  // KEAMANAN AKUN
                  // ========================================
                  _buildCard(
                    icon: Icons.shield_outlined,
                    title: 'Keamanan Akun',
                    subtitle: 'Ubah password secara berkala untuk menjaga keamanan akun.',
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

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5F1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: darkGreen, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jaga kerahasiaan password Anda. Jangan membagikan password kepada orang lain.',
                            style: TextStyle(
                              fontSize: 12,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==========================================================
  // TAMPILAN ERROR
  // ==========================================================

  Widget _buildErrorState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_outlined,
                size: 38,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Profil tidak dapat dimuat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Periksa koneksi internet atau coba kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textGrey),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadProfil,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

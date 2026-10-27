import 'package:flutter/material.dart';

import '../../app_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk mengambil isi setiap kolom form.
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();

  // Mengatur apakah password ditampilkan sebagai teks biasa.
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;

  @override
  void dispose() {
    // Membersihkan controller saat halaman ditutup.
    _namaController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  // Menampilkan pesan singkat kepada pengguna.
  void _tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // Memvalidasi data sebelum proses registrasi dijalankan.
  void _register() {
    final nama = _namaController.text.trim();
    final noHp = _noHpController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final konfirmasi = _konfirmasiPasswordController.text;

    // Memastikan seluruh kolom wajib telah diisi.
    if (nama.isEmpty ||
        noHp.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        konfirmasi.isEmpty) {
      _tampilkanPesan('Mohon lengkapi semua data.');
      return;
    }

    // Memastikan format email valid.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _tampilkanPesan('Format email tidak valid.');
      return;
    }

    // Password minimal terdiri dari delapan karakter.
    if (password.length < 8) {
      _tampilkanPesan('Password minimal 8 karakter.');
      return;
    }

    // Memastikan password dan konfirmasinya sama.
    if (password != konfirmasi) {
      _tampilkanPesan('Konfirmasi password tidak sesuai.');
      return;
    }

    // Catatan: bagian ini masih simulasi.
    // Hubungkan ke endpoint registrasi Laravel jika API sudah tersedia.
    _tampilkanPesan('Registrasi berhasil. Silakan login.');

    Navigator.pop(context);
  }

  // Membuat kolom input dengan tampilan seragam seperti versi web.
  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 12, color: Color(0xFF172033)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Tidak menggunakan AppBar agar layout menyerupai versi web.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              // Membatasi lebar form agar tetap rapi di layar besar.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Judul dan deskripsi halaman registrasi.
                  const Text(
                    'Daftar Nasabah',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Isi data berikut untuk membuat akun nasabah.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
                  ),

                  const SizedBox(height: 25),

                  // Kolom nama lengkap.
                  _field(
                    label: 'Nama lengkap',
                    hint: 'Masukkan nama lengkap',
                    controller: _namaController,
                  ),

                  const SizedBox(height: 15),

                  // Kolom nomor telepon.
                  _field(
                    label: 'Nomor telepon',
                    hint: 'Masukkan nomor telepon',
                    controller: _noHpController,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 15),

                  // Kolom email.
                  _field(
                    label: 'Email',
                    hint: 'Masukkan email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 15),

                  // Kolom password dengan tombol tampil/sembunyikan.
                  _field(
                    label: 'Password',
                    hint: 'Minimal 8 karakter',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: const Color(0xFF667085),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Kolom konfirmasi password.
                  _field(
                    label: 'Konfirmasi password',
                    hint: 'Ulangi password',
                    controller: _konfirmasiPasswordController,
                    obscureText: _obscureKonfirmasi,
                    suffixIcon: IconButton(
                      tooltip: _obscureKonfirmasi
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _obscureKonfirmasi
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: const Color(0xFF667085),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureKonfirmasi = !_obscureKonfirmasi;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 23),

                  // Tombol daftar dengan warna utama aplikasi.
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'Daftar sebagai nasabah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // Mengarahkan pengguna yang sudah memiliki akun
                  // kembali ke halaman login.
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF172033),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Nama aplikasi pada bagian bawah halaman.
                  const Center(
                    child: Text(
                      'Bank Sampah Griya Ayu',
                      style: TextStyle(fontSize: 10, color: Color(0xFF667085)),
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
}

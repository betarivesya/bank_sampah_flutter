import 'package:flutter/material.dart';

import '../../app_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noHpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();
    final alamat = _alamatController.text.trim();
    final password = _passwordController.text.trim();
    final konfirmasi = _konfirmasiPasswordController.text.trim();

    if (nama.isEmpty ||
        email.isEmpty ||
        alamat.isEmpty ||
        password.isEmpty ||
        konfirmasi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data yang wajib diisi.')),
      );
      return;
    }

    if (password != konfirmasi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak sesuai.')),
      );
      return;
    }

    // Sementara hanya simulasi.
    // Nanti disambungkan ke Laravel API.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrasi berhasil. Silakan login.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buat Akun Nasabah',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Lengkapi data berikut untuk membuat akun.',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _namaController,
                decoration: AppDecorations.inputDecoration(
                  'Nama Lengkap',
                  icon: Icons.person_outline,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: AppDecorations.inputDecoration(
                  'Email',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _alamatController,
                maxLines: 2,
                decoration: AppDecorations.inputDecoration(
                  'Alamat',
                  icon: Icons.location_on_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _noHpController,
                keyboardType: TextInputType.phone,
                decoration: AppDecorations.inputDecoration(
                  'No. HP (Opsional)',
                  icon: Icons.phone_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration:
                    AppDecorations.inputDecoration(
                      'Password',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _konfirmasiPasswordController,
                obscureText: _obscureKonfirmasi,
                decoration:
                    AppDecorations.inputDecoration(
                      'Konfirmasi Password',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKonfirmasi
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureKonfirmasi = !_obscureKonfirmasi;
                          });
                        },
                      ),
                    ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

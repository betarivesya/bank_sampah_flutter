import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../services/api_service.dart';

class UbahPasswordScreen extends StatefulWidget {
  final int idNasabah;

  const UbahPasswordScreen({super.key, required this.idNasabah});

  @override
  State<UbahPasswordScreen> createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordLamaController = TextEditingController();
  final _passwordBaruController = TextEditingController();
  final _konfirmasiController = TextEditingController();

  bool _sembunyikanLama = true;
  bool _sembunyikanBaru = true;
  bool _sembunyikanKonfirmasi = true;
  bool _sedangMenyimpan = false;

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _simpanPassword() async {
    FocusScope.of(context).unfocus();

    if (_sedangMenyimpan) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sedangMenyimpan = true;
    });

    try {
      await ApiService.ubahPasswordNasabah(
        idNasabah: widget.idNasabah,
        passwordLama: _passwordLamaController.text,
        passwordBaru: _passwordBaruController.text,
        konfirmasiPassword: _konfirmasiController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final pesan = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sedangMenyimpan = false;
        });
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool tersembunyi,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: tersembunyi,
          enabled: !_sedangMenyimpan,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13),
            suffixIcon: IconButton(
              onPressed: _sedangMenyimpan ? null : onToggle,
              icon: Icon(
                tersembunyi
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Ubah Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Gunakan password yang kuat dan jangan '
                          'membagikannya kepada orang lain.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildPasswordField(
                  label: 'Password Lama',
                  hint: 'Masukkan password lama',
                  controller: _passwordLamaController,
                  tersembunyi: _sembunyikanLama,
                  onToggle: () {
                    setState(() {
                      _sembunyikanLama = !_sembunyikanLama;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password lama wajib diisi.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildPasswordField(
                  label: 'Password Baru',
                  hint: 'Minimal 8 karakter',
                  controller: _passwordBaruController,
                  tersembunyi: _sembunyikanBaru,
                  onToggle: () {
                    setState(() {
                      _sembunyikanBaru = !_sembunyikanBaru;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password baru wajib diisi.';
                    }

                    if (value.length < 8) {
                      return 'Password minimal 8 karakter.';
                    }

                    if (value == _passwordLamaController.text) {
                      return 'Password baru harus berbeda.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildPasswordField(
                  label: 'Konfirmasi Password Baru',
                  hint: 'Masukkan ulang password baru',
                  controller: _konfirmasiController,
                  tersembunyi: _sembunyikanKonfirmasi,
                  onToggle: () {
                    setState(() {
                      _sembunyikanKonfirmasi = !_sembunyikanKonfirmasi;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password wajib diisi.';
                    }

                    if (value != _passwordBaruController.text) {
                      return 'Konfirmasi password tidak cocok.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sedangMenyimpan ? null : _simpanPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.6,
                      ),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sedangMenyimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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

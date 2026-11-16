import 'package:flutter/material.dart';

import '../../app_styles.dart';
import 'ubah_password_screen.dart';

class LoginKeamananScreen extends StatefulWidget {
  final int idNasabah;

  const LoginKeamananScreen({super.key, required this.idNasabah});

  @override
  State<LoginKeamananScreen> createState() => _LoginKeamananScreenState();
}

class _LoginKeamananScreenState extends State<LoginKeamananScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Login dan Keamanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Keamanan Akun',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primary),
              ),
              title: const Text(
                'Ubah Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Perbarui password akunmu',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UbahPasswordScreen(idNasabah: widget.idNasabah),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

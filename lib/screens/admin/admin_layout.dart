import 'package:bank_sampah_flutter/services/api_service.dart';
import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard.dart';
import 'admin_drawer.dart';
import 'kelola_sampah_screen.dart';
import 'manajemen_pengguna_screen.dart';
import 'laporan_screen.dart';
import 'manajemen_keuangan_screen.dart';
import 'pengaturan_akun_screen.dart';
import 'admin_riwayat_transaksi_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String _selectedMenu = 'dashboard';

  // ==========================================================
  // PILIH MENU
  // ==========================================================

  void _selectMenu(String menu) {
    setState(() {
      _selectedMenu = menu;
    });
  }

  // ==========================================================
  // LOGOUT DARI MENU
  // ==========================================================

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Keluar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF71847F)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // KONFIRMASI KELUAR DENGAN TOMBOL BACK HP
  // ==========================================================

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Keluar dari aplikasi?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF71847F)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // BODY SESUAI MENU
  // ==========================================================

  Widget _buildBody() {
    switch (_selectedMenu) {
      case 'sampah':
        return const KelolaSampahScreen();

      case 'pengguna':
        return const ManajemenPenggunaScreen();

      case 'laporan':
        return const LaporanScreen();

      case 'riwayat-transaksi':
        return const AdminRiwayatTransaksiScreen();

      case 'keuangan':
        return const ManajemenKeuanganScreen();

      case 'pengaturan-akun':
        return PengaturanAkunScreen(currentEmail: ApiService.currentUserEmail);

      case 'dashboard':
      default:
        return const AdminDashboard();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // ------------------------------------------------------
        // Jika sedang berada di menu selain Dashboard,
        // tombol Back HP akan kembali ke Dashboard.
        // ------------------------------------------------------

        if (_selectedMenu != 'dashboard') {
          setState(() {
            _selectedMenu = 'dashboard';
          });
          return;
        }

        // ------------------------------------------------------
        // Jika sudah berada di Dashboard,
        // tampilkan konfirmasi keluar aplikasi.
        // ------------------------------------------------------

        _showExitConfirmation();
      },

      child: Scaffold(
        // ======================================================
        // DRAWER
        // ======================================================

        drawer: AdminDrawer(
          selectedMenu: _selectedMenu,
          onMenuSelected: _selectMenu,
          onLogout: _logout,
          isSuperadmin:
              ApiService.currentUserRole?.toLowerCase() == 'superadmin',
        ),

        // ======================================================
        // APP BAR
        // ======================================================
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F463D),
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,

          // Logo dan nama
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F806B),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Image.asset(
                  'assets/images/logo-griya-ayu-sidebar.png',
                  width: 46,
                  height: 46,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(width: 10),

              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SIRAYA',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bank Sampah Griya Ayu',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ======================================================
        // BODY
        // ======================================================
        body: _buildBody(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard.dart';
import 'admin_drawer.dart';
import 'kelola_sampah_screen.dart';
import 'manajemen_pengguna_screen.dart';
import 'admin_notification_screen.dart';

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
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
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
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
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
        return const Center(
          child: Text(
            'Laporan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );

      case 'notifikasi':
        return const AdminNotificationScreen();

      case 'dashboard':
      default:
        return const AdminDashboard();
    }
  }

  // ==========================================================
  // JUDUL APPBAR
  // ==========================================================

  String _getTitle() {
    switch (_selectedMenu) {
      case 'sampah':
        return 'Kelola Sampah';

      case 'pengguna':
        return 'Manajemen Pengguna';

      case 'laporan':
        return 'Laporan';

      case 'notifikasi':
        return 'Notifikasi Admin';

      case 'dashboard':
      default:
        return 'Dashboard Admin';
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
        ),

        // ======================================================
        // APP BAR
        // ======================================================
        appBar: AppBar(
          backgroundColor: const Color(0xFF075B4F),
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,

          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Bank Sampah Griya Ayu',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),

          actions: [
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminNotificationScreen(),
                  ),
                );
              },
              icon: const Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 25),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 8, height: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ======================================================
        // BODY
        // ======================================================
        body: _buildBody(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard.dart';
import 'admin_drawer.dart';
import 'kelola_sampah_screen.dart';
import 'manajemen_pengguna_screen.dart';

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
  // LOGOUT
  // ==========================================================

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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

      default:
        return const AdminDashboard();
    }
  }

  // ==========================================================
  // MENU YANG BELUM DIBUAT
  // ==========================================================

  Widget _buildComingSoon({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4ED),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF2E8B72)),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: AppColors.background,

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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi baru.')),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 25),

                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: _buildBody(),
    );
  }
}

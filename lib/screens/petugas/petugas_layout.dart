import 'package:bank_sampah_flutter/app_styles.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/setoran_model.dart';
import '../auth/login_screen.dart';

import 'notifikasi_petugas.dart';
import 'petugas_dashboard.dart';
import 'petugas_drawer.dart';
import 'setoran_screen.dart';
import 'penarikan_screen.dart';
import 'riwayat_transaksi_screen.dart';

class PetugasLayout extends StatefulWidget {
  final int idPetugas;

  const PetugasLayout({super.key, required this.idPetugas});

  @override
  State<PetugasLayout> createState() => _PetugasLayoutState();
}

class _PetugasLayoutState extends State<PetugasLayout> {
  static const Color darkGreen = Color(0xFF075B4F);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textDark = Color(0xFF172033);

  String _selectedMenu = 'dashboard';

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun Petugas?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                ApiService.clearSession();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // KONFIRMASI KELUAR DENGAN TOMBOL BACK
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
            style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari aplikasi Bank Sampah Griya Ayu?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, true);
              },
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
      case 'setoran':
        return SetoranScreen(idPetugas: widget.idPetugas);

      case 'riwayat':
        return const RiwayatTransaksiScreen();

      case 'penarikan':
        return PenarikanScreen(idPetugas: widget.idPetugas);

      case 'dashboard':
      default:
        return PetugasDashboard(onMenuSelected: _selectMenu);
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

        if (_selectedMenu != 'dashboard') {
          setState(() {
            _selectedMenu = 'dashboard';
          });
          return;
        }

        _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: background,

        // ======================================================
        // DRAWER
        // ======================================================
        drawer: PetugasDrawer(
          selectedMenu: _selectedMenu,
          onMenuSelected: _selectMenu,
          onLogout: _logout,
        ),

        // ======================================================
        // APP BAR
        // ======================================================
        appBar: AppBar(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,

          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B72),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 23,
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

          actions: [
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotifikasiPetugas(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_none_outlined, size: 25),
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

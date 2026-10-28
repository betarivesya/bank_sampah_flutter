import 'package:bank_sampah_flutter/services/api_service.dart';
import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard.dart';
import 'admin_drawer.dart';
import 'kelola_sampah_screen.dart';
import 'manajemen_pengguna_screen.dart';
import 'admin_notification_screen.dart';
import 'laporan_screen.dart';

import 'dart:async';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String _selectedMenu = 'dashboard';

  int _jumlahNotifikasiBelumDibaca = 0;
  Timer? _timerNotifikasi;

  @override
  void initState() {
    super.initState();

    _muatJumlahNotifikasi();

    // Periksa notifikasi baru setiap 30 detik
    _timerNotifikasi = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _muatJumlahNotifikasi(),
    );
  }

  @override
  void dispose() {
    _timerNotifikasi?.cancel();
    super.dispose();
  }

  Future<void> _muatJumlahNotifikasi() async {
    try {
      final response = await ApiService.getNotifikasiAdmin();
      final dynamic data = response['data'];

      if (data is! List || !mounted) return;

      final jumlah = data.where((item) {
        if (item is! Map) return false;

        final dibaca = item['dibaca'];

        final sudahDibaca =
            dibaca == true ||
            dibaca.toString() == '1' ||
            dibaca.toString().toLowerCase() == 'true';

        return !sudahDibaca;
      }).length;

      if (!mounted) return;

      setState(() {
        _jumlahNotifikasiBelumDibaca = jumlah;
      });
    } catch (_) {}
  }

  Future<void> _bukaNotifikasi() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminNotificationScreen()),
    );

    // Perbaiki bagde setelah halaman notifikasi ditutup
    if (mounted) {
      await _muatJumlahNotifikasi();
    }
  }

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
        return const LaporanScreen();

      case 'notifikasi':
        return const AdminNotificationScreen();

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
        ),

        // ======================================================
        // APP BAR
        // ======================================================
        appBar: AppBar(
          backgroundColor: const Color(0xFF075B4F),
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
                  color: const Color(0xFF2E8B72),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                'Griya Ayu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          actions: [
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: _bukaNotifikasi,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_outlined, size: 25),

                  if (_jumlahNotifikasiBelumDibaca > 0)
                    Positioned(
                      right: -9,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),

                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),

                        alignment: Alignment.center,
                        child: Text(
                          _jumlahNotifikasiBelumDibaca > 99
                              ? '99+'
                              : '$_jumlahNotifikasiBelumDibaca',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

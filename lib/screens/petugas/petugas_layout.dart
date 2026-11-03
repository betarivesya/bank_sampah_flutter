import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/setoran_model.dart';
import '../auth/login_screen.dart';

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
  static const Color textGrey = Color(0xFF7B8A89);

  String _selectedMenu = 'dashboard';

  void _selectMenu(String menu) {
    setState(() {
      _selectedMenu = menu;
    });
  }

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
                backgroundColor: Colors.redAccent,
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
                Navigator.pop(context, true); // Keluar dari aplikasi
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNotifications() async {
    try {
      final now = DateTime.now();
      final hasil = await Future.wait([
        ApiService.getPetugasSetoranPage(
          bulan: now.month,
          tahun: now.year,
          page: 1,
          perPage: 5,
        ),
        ApiService.getPetugasPenarikanPage(
          bulan: now.month,
          tahun: now.year,
          page: 1,
          perPage: 5,
        ),
      ]);

      final setoran = hasil[0] as PetugasPage<SetoranModel>;
      final penarikan = hasil[1] as PetugasPage<Map<String, dynamic>>;
      final aktivitas = <String>[];

      for (final item in setoran.items.take(3)) {
        aktivitas.add('Setoran ${item.namaNasabah} - ${item.namaSampah}');
      }
      for (final item in penarikan.items.take(3)) {
        aktivitas.add(
          'Penarikan ${item['nama_nasabah']?.toString() ?? 'nasabah'} - '
          '${item['status']?.toString() ?? 'menunggu'}',
        );
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: darkGreen),
              SizedBox(width: 10),
              Text('Aktivitas Terbaru'),
            ],
          ),
          content: aktivitas.isEmpty
              ? const Text('Belum ada aktivitas terbaru.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: aktivitas.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: Text(aktivitas[index]),
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil notifikasi.')),
      );
    }
  }

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

  String _getTitle() {
    switch (_selectedMenu) {
      case 'setoran':
        return 'Setor Sampah';

      case 'riwayat':
        return 'Riwayat Transaksi';

      case 'penarikan':
        return 'Penarikan Saldo';

      case 'dashboard':
      default:
        return 'Dashboard Petugas';
    }
  }

  String _getSubtitle() {
    switch (_selectedMenu) {
      case 'setoran':
        return 'Input setoran sampah nasabah';

      case 'riwayat':
        return 'Riwayat aktivitas transaksi';

      case 'penarikan':
        return 'Verifikasi pengajuan penarikan';

      case 'dashboard':
      default:
        return 'Bank Sampah Griya Ayu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Kalau sedang bukan di Dashboard,
        // tombol Back kembali ke Dashboard.
        if (_selectedMenu != 'dashboard') {
          setState(() {
            _selectedMenu = 'dashboard';
          });
          return;
        }

        // Kalau sudah di Dashboard,
        // tampilkan konfirmasi keluar.
        _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: background,

        drawer: PetugasDrawer(
          selectedMenu: _selectedMenu,
          onMenuSelected: _selectMenu,
          onLogout: _logout,
        ),

        appBar: AppBar(
          backgroundColor: _selectedMenu == 'dashboard'
              ? background
              : darkGreen,
          foregroundColor: _selectedMenu == 'dashboard'
              ? textDark
              : Colors.white,
          elevation: 0,
          titleSpacing: 0,

          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTitle(),
                style: TextStyle(
                  color: _selectedMenu == 'dashboard' ? textDark : Colors.white,
                  fontSize: _selectedMenu == 'dashboard' ? 22 : 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _getSubtitle(),
                style: TextStyle(
                  color: _selectedMenu == 'dashboard'
                      ? textGrey
                      : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Aktivitas terbaru',
              onPressed: _showNotifications,
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 25,
                color: _selectedMenu == 'dashboard' ? darkGreen : Colors.white,
              ),
            ),

            const SizedBox(width: 4),
          ],
        ),

        body: _buildBody(),
      ),
    );
  }
}

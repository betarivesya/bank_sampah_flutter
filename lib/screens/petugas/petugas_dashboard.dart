import 'package:flutter/material.dart';

import '../../data/petugas_dummy_data.dart';
import 'nasabah_screen.dart';
import 'setoran_screen.dart';
import 'penarikan_screen.dart';
import 'petugas_drawer.dart';

class PetugasDashboard extends StatefulWidget {
  const PetugasDashboard({super.key});

  @override
  State<PetugasDashboard> createState() => _PetugasDashboardState();
}

class _PetugasDashboardState extends State<PetugasDashboard> {
  // ==========================================================
  // WARNA APLIKASI
  // ==========================================================

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color lightGreen = Color(0xFFE6F4ED);

  static const Color background = Color(0xFFF5F7F8);
  static const Color textDark = Color(0xFF24413D);
  static const Color textGrey = Color(0xFF7B8A89);

  // ==========================================================
  // FORMAT RUPIAH
  // ==========================================================

  String formatRupiah(num value) {
    final number = value.round().toString();
    final result = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      final position = number.length - i;

      result.write(number[i]);

      if (position > 1 && position % 3 == 1) {
        result.write('.');
      }
    }

    return 'Rp ${result.toString()}';
  }

  // ==========================================================
  // DATA STATISTIK
  // ==========================================================

  double get totalSaldo {
    return PetugasDummyData.nasabah.fold<double>(
      0,
      (sum, item) => sum + item.saldo,
    );
  }

  double get totalSampah {
    return PetugasDummyData.setoran.fold<double>(
      0,
      (sum, item) => sum + item.beratKg,
    );
  }

  int get totalPending {
    return PetugasDummyData.penarikan
        .where((item) => item.status == 'Menunggu')
        .length;
  }

  // ==========================================================
  // NAVIGASI KE HALAMAN
  // ==========================================================

  Future<void> bukaHalaman(Widget halaman) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => halaman),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  void konfirmasiLogout() {
    showDialog(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
              },
              child: const Text('Batal', style: TextStyle(color: textGrey)),
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
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fitur logout akan disambungkan ke halaman login.',
                    ),
                  ),
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
  // NOTIFIKASI
  // ==========================================================

  void tampilkanNotifikasi() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: darkGreen),
              SizedBox(width: 10),
              Text('Notifikasi'),
            ],
          ),
          content: Text(
            totalPending == 0
                ? 'Tidak ada pengajuan penarikan yang menunggu.'
                : 'Ada $totalPending pengajuan penarikan '
                      'yang perlu diverifikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // STATISTIK CARD
  // ==========================================================

  Widget statistikCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: darkGreen, size: 22),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MENU CEPAT
  // ==========================================================

  Widget menuCepat({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: darkGreen, size: 25),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: textGrey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // AKTIVITAS
  // ==========================================================

  Widget aktivitasCard({
    required String nama,
    required String jenis,
    required String berat,
    required String nominal,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.recycling_rounded,
              color: darkGreen,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$jenis • $berat',
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
              ],
            ),
          ),

          Text(
            nominal,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RIWAYAT TRANSAKSI
  // ==========================================================

  void lihatRiwayat() {
    final daftar = [...PetugasDummyData.setoran];

    daftar.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 43,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: daftar.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada transaksi.',
                          style: TextStyle(color: textGrey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: daftar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final item = daftar[index];

                          return aktivitasCard(
                            nama: item.namaNasabah,
                            jenis: item.namaSampah,
                            berat: '${item.beratKg.toStringAsFixed(1)} Kg',
                            nominal: '+ ${formatRupiah(item.total)}',
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final aktivitas = [...PetugasDummyData.setoran];

    aktivitas.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return Scaffold(
      backgroundColor: background,
      drawer: PetugasDrawer(
        onRiwayat: lihatRiwayat,
        onLogout: konfirmasiLogout,
      ),

      // ======================================================
      // APP BAR
      // ======================================================
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,

        titleSpacing: 0,

        // Ikon hamburger akan muncul otomatis
        // karena Scaffold memakai Drawer.
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Petugas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 2),

            Text(
              'Bank Sampah Griya Ayu',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),

        actions: [
          // ==================================================
          // NOTIFIKASI
          // ==================================================

          IconButton(
            onPressed: tampilkanNotifikasi,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 25),

                if (totalPending > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF716B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: RefreshIndicator(
        color: darkGreen,

        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 350));

          if (mounted) {
            setState(() {});
          }
        },

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(15, 16, 15, 25),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HERO
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [darkGreen, primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(21),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 13),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, Petugas 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Siap melayani aktivitas Bank Sampah hari ini?',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // RINGKASAN
              // ==================================================
              const Text(
                'Ringkasan Hari Ini',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 11),

              Row(
                children: [
                  Expanded(
                    child: statistikCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Nasabah',
                      value: '${PetugasDummyData.nasabah.length}',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: statistikCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Total Saldo',
                      value: formatRupiah(totalSaldo),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: statistikCard(
                      icon: Icons.scale_outlined,
                      title: 'Total Sampah',
                      value: '${totalSampah.toStringAsFixed(1)} Kg',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: statistikCard(
                      icon: Icons.pending_actions_outlined,
                      title: 'Pending',
                      value: '$totalPending',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==================================================
              // MENU UTAMA
              // ==================================================
              const Text(
                'Menu Utama',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 11),

              menuCepat(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Penarikan Saldo',
                subtitle: 'Verifikasi pengajuan penarikan',
                onTap: () {
                  bukaHalaman(const PenarikanScreen());
                },
              ),

              const SizedBox(height: 10),

              menuCepat(
                icon: Icons.people_alt_outlined,
                title: 'Data Nasabah',
                subtitle: 'Lihat data dan saldo nasabah',
                onTap: () {
                  bukaHalaman(const NasabahScreen());
                },
              ),

              const SizedBox(height: 10),

              menuCepat(
                icon: Icons.recycling_outlined,
                title: 'Setor Sampah',
                subtitle: 'Input dan catat setoran sampah',
                onTap: () {
                  bukaHalaman(const SetoranScreen());
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // AKTIVITAS TERBARU
              // ==================================================
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Aktivitas Terbaru',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: lihatRiwayat,
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              if (aktivitas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, color: textGrey, size: 38),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada aktivitas.',
                        style: TextStyle(color: textGrey),
                      ),
                    ],
                  ),
                )
              else
                ...aktivitas
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: aktivitasCard(
                          nama: item.namaNasabah,
                          jenis: item.namaSampah,
                          berat: '${item.beratKg.toStringAsFixed(1)} Kg',
                          nominal: '+ ${formatRupiah(item.total)}',
                        ),
                      ),
                    ),

              const SizedBox(height: 10),

              // ==================================================
              // INFO
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: darkGreen,
                      size: 22,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Petugas dapat melayani setoran sampah '
                        'dan memverifikasi pengajuan penarikan saldo nasabah.',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ALIAS
// Supaya tetap kompatibel dengan preview/main.
// ============================================================

class PetugasDashboardScreen extends StatelessWidget {
  const PetugasDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PetugasDashboard();
  }
}

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

import 'nasabah_screen.dart';
import 'setoran_screen.dart';

class PetugasDashboard extends StatefulWidget {
  final Function(String) onMenuSelected;

  const PetugasDashboard({super.key, required this.onMenuSelected});

  @override
  State<PetugasDashboard> createState() => _PetugasDashboardState();
}

class _PetugasDashboardState extends State<PetugasDashboard> {
  // ============================================================
  // WARNA APLIKASI
  // ============================================================

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color lightGreen = Color(0xFFE8F5F1);

  static const Color background = Color(0xFFF6F8F7);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7B8A89);

  // ============================================================
  // DATA DASHBOARD
  // ============================================================

  bool isLoading = true;

  int totalNasabah = 0;
  int totalSetoran = 0;
  int totalPenarikan = 0;
  int setoranHariIni = 0;
  int penarikanHariIni = 0;

  double totalSaldo = 0;
  double totalSampah = 0;

  int totalPending = 0;

  List<dynamic> aktivitasTerbaru = [];
  bool isLoadingAktivitas = true;

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

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

  // ============================================================
  // LOAD DATA DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final data = await ApiService.getPetugasDashboard();

      if (!mounted) return;

      setState(() {
        totalNasabah =
            int.tryParse(data['total_nasabah']?.toString() ?? '0') ?? 0;

        totalSetoran =
            int.tryParse(data['total_setoran']?.toString() ?? '0') ?? 0;

        totalPenarikan =
            int.tryParse(data['total_penarikan']?.toString() ?? '0') ?? 0;

        setoranHariIni =
            int.tryParse(data['setoran_hari_ini']?.toString() ?? '0') ?? 0;

        penarikanHariIni =
            int.tryParse(data['penarikan_hari_ini']?.toString() ?? '0') ?? 0;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD PETUGAS ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data dashboard.')),
      );
    }
  }

  Future<void> _loadAktivitas() async {
    try {
      final hasilSetoran = await ApiService.getSetoran();
      final hasilPenarikan = await ApiService.getPenarikanPetugas();

      final List<Map<String, dynamic>> data = [];

      // Aktivitas Setoran
      for (final item in hasilSetoran) {
        data.add({
          'nama': item.namaNasabah,
          'jenis': 'Setoran',
          'detail': '${item.namaSampah} • ${item.totalBerat} kg',
          'nominal': item.totalNilai,
          'tanggal': DateTime.tryParse(item.tanggal) ?? DateTime(2000),
          'icon': Icons.recycling_rounded,
          'warna': primaryGreen,
        });
      }

      // Aktivitas Penarikan
      for (final item in hasilPenarikan) {
        data.add({
          'nama': item['nama_nasabah']?.toString() ?? 'Nasabah',
          'jenis': 'Penarikan',
          'detail': 'Penarikan Saldo',
          'nominal': double.tryParse(item['nominal']?.toString() ?? '0') ?? 0,
          'tanggal':
              DateTime.tryParse(item['tgl_pengajuan']?.toString() ?? '') ??
              DateTime(2000),
          'icon': Icons.account_balance_wallet_rounded,
          'warna': Colors.orange,
        });
      }

      // Urutkan dari transaksi paling baru
      data.sort((a, b) {
        return (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime);
      });

      if (!mounted) return;

      setState(() {
        aktivitasTerbaru = data.take(5).toList();
        isLoadingAktivitas = false;
      });
    } catch (e) {
      debugPrint('AKTIVITAS TERBARU ERROR: $e');

      if (!mounted) return;

      setState(() {
        aktivitasTerbaru = [];
        isLoadingAktivitas = false;
      });
    }
  }

  // ============================================================
  // NOTIFIKASI
  // ============================================================

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

  // ============================================================
  // STATISTIK CARD
  // ============================================================

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

  // ============================================================
  // MENU CEPAT
  // ============================================================

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

  // ============================================================
  // AKTIVITAS CARD
  // ============================================================

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

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadAktivitas();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: darkGreen,
      onRefresh: () async {
        await Future.wait([_loadDashboard(), _loadAktivitas()]);
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
                    value: isLoading ? '...' : '$totalNasabah',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: statistikCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Total Saldo',
                    value: isLoading ? '...' : formatRupiah(totalSaldo),
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
                    value: isLoading
                        ? '...'
                        : '${totalSampah.toStringAsFixed(1)} Kg',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: statistikCard(
                    icon: Icons.pending_actions_outlined,
                    title: 'Pending',
                    value: isLoading ? '...' : '$totalPending',
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

            // ==================================================
            // PENARIKAN
            // ==================================================
            menuCepat(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Penarikan Saldo',
              subtitle: 'Verifikasi pengajuan penarikan',
              onTap: () {
                widget.onMenuSelected('penarikan');
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // SETOR SAMPAH
            // ==================================================
            menuCepat(
              icon: Icons.recycling_outlined,
              title: 'Setor Sampah',
              subtitle: 'Input dan catat setoran sampah',
              onTap: () {
                widget.onMenuSelected('setoran');
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
                  onTap: () {
                    widget.onMenuSelected('riwayat');
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            // ==================================================
            // AKTIVITAS TERBARU
            // ==================================================
            if (isLoadingAktivitas)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: darkGreen),
                ),
              )
            else if (aktivitasTerbaru.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history_rounded, color: textGrey, size: 38),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada aktivitas transaksi,',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textGrey, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: aktivitasTerbaru.map((item) {
                  final jenis = item['jenis'] as String;
                  final nominal = (item['nominal'] as num?)?.toDouble() ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Container(
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
                              color: (item['warna'] as Color).withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: item['warna'] as Color,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama']?.toString() ?? 'Nasabah',
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$jenis • ${item['detail']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: textGrey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${jenis == 'Setoran' ? '+' : '-'}${formatRupiah(nominal)}',
                            style: TextStyle(
                              color: jenis == 'Setoran'
                                  ? darkGreen
                                  : Colors.orange.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

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
                  Icon(Icons.info_outline_rounded, color: darkGreen, size: 22),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Petugas dapat melayani setoran sampah '
                      'dan memverifikasi pengajuan penarikan '
                      'saldo nasabah.',
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
    );
  }
}

// ============================================================
// ALIAS
// ============================================================

class PetugasDashboardScreen extends StatelessWidget {
  const PetugasDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PetugasDashboard(onMenuSelected: (menu) {});
  }
}

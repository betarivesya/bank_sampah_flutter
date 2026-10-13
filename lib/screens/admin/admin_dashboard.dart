import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color background = Color(0xFFF5F7F8);
  static const Color textDark = Color(0xFF24413D);
  static const Color textGrey = Color(0xFF7B8A89);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ============================================================
  // DATA DASHBOARD
  // ============================================================

  bool isLoading = true;

  int nasabahAktif = 0;
  double nilaiSetoran = 0;
  double saldoNasabah = 0;
  int menungguValidasi = 0;
  int penarikanPending = 0;
  int transaksiDisetujui = 0;

  List<dynamic> grafikSetoran = [];
  List<dynamic> transaksiTerbaru = [];

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String formatRupiah(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp${buffer.toString()}';
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadDashboard() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final data = await ApiService.getAdminDashboard();

      if (!mounted) return;

      setState(() {
        nasabahAktif =
            int.tryParse(data['nasabah_aktif']?.toString() ?? '0') ?? 0;

        nilaiSetoran =
            double.tryParse(data['nilai_setoran']?.toString() ?? '0') ?? 0;

        saldoNasabah =
            double.tryParse(data['saldo_nasabah']?.toString() ?? '0') ?? 0;

        menungguValidasi =
            int.tryParse(data['menunggu_validasi']?.toString() ?? '0') ?? 0;

        penarikanPending =
            int.tryParse(data['penarikan_pending']?.toString() ?? '0') ?? 0;

        transaksiDisetujui =
            int.tryParse(data['transaksi_disetujui']?.toString() ?? '0') ?? 0;

        grafikSetoran = List<dynamic>.from(data['grafik_setoran'] ?? []);

        transaksiTerbaru = List<dynamic>.from(data['transaksi_terbaru'] ?? []);

        isLoading = false;
      });
    } catch (e) {
      debugPrint('ADMIN DASHBOARD ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data dashboard.')),
      );
    }
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminDashboard.background,

      child: RefreshIndicator(
        color: AdminDashboard.darkGreen,
        onRefresh: _loadDashboard,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildWelcomeCard(),

              const SizedBox(height: 20),

              _buildSectionTitle('Ringkasan'),

              const SizedBox(height: 12),

              _buildStatistics(),

              const SizedBox(height: 22),

              _buildChartSection(),

              const SizedBox(height: 22),

              _buildLatestTransactions(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdminDashboard.darkGreen, AdminDashboard.primaryGreen],
        ),

        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),

              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.manage_accounts_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Halo, Admin 👋',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Siap mengelola aktivitas Bank Sampah hari ini?',

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        color: AdminDashboard.textDark,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return GridView.count(
      crossAxisCount: 2,

      crossAxisSpacing: 12,
      mainAxisSpacing: 12,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      childAspectRatio: 1.55,

      children: [
        _statisticCard(
          title: 'Nasabah Aktif',

          value: isLoading ? '...' : '$nasabahAktif',

          icon: Icons.people_outline_rounded,
        ),

        _statisticCard(
          title: 'Nilai Setoran',

          value: isLoading ? '...' : formatRupiah(nilaiSetoran),

          icon: Icons.payments_outlined,
        ),

        _statisticCard(
          title: 'Saldo Nasabah',

          value: isLoading ? '...' : formatRupiah(saldoNasabah),

          icon: Icons.account_balance_wallet_outlined,
        ),

        _statisticCard(
          title: 'Menunggu Validasi',

          value: isLoading ? '...' : '$menungguValidasi',

          icon: Icons.pending_actions_outlined,
        ),

        _statisticCard(
          title: 'Penarikan Pending',

          value: isLoading ? '...' : '$penarikanPending',

          icon: Icons.money_outlined,
        ),

        _statisticCard(
          title: 'Transaksi Disetujui',

          value: isLoading ? '...' : '$transaksiDisetujui',

          icon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIC CARD
  // ============================================================

  Widget _statisticCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 8,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,

                decoration: BoxDecoration(
                  color: AdminDashboard.primaryGreen.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(icon, color: AdminDashboard.primaryGreen, size: 19),
              ),

              const Spacer(),

              const Icon(
                Icons.more_horiz_rounded,

                color: Colors.grey,

                size: 18,
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,

            style: const TextStyle(
              color: AdminDashboard.textDark,

              fontSize: 17,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,

            style: const TextStyle(
              color: AdminDashboard.textGrey,

              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART
  // ============================================================

  Widget _buildChartSection() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 8,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Statistik Setoran 2026',

                  style: TextStyle(
                    color: AdminDashboard.textDark,

                    fontSize: 16,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '2026',

                style: TextStyle(color: AdminDashboard.textGrey, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 180,

            child: CustomPaint(
              painter: _LineChartPainter(grafikSetoran),

              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSAKSI TERBARU
  // ============================================================

  Widget _buildLatestTransactions() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 8,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Transaksi Terbaru',

            style: TextStyle(
              color: AdminDashboard.textDark,

              fontSize: 16,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (transaksiTerbaru.isEmpty)
            const Padding(
              padding: EdgeInsets.all(15),

              child: Center(
                child: Text(
                  'Belum ada transaksi.',

                  style: TextStyle(
                    color: AdminDashboard.textGrey,

                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            ...transaksiTerbaru.map(
              (item) => _transactionItem(Map<String, dynamic>.from(item)),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSAKSI ITEM
  // ============================================================

  Widget _transactionItem(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? '';

    final bool selesai = status == 'Selesai';

    final nominal = double.tryParse(item['nominal']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),

        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: AdminDashboard.primaryGreen.withValues(alpha: 0.10),

              borderRadius: BorderRadius.circular(11),
            ),

            child: const Icon(
              Icons.recycling_outlined,

              color: AdminDashboard.primaryGreen,

              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item['nama']?.toString() ?? '-',

                  style: const TextStyle(
                    color: AdminDashboard.textDark,

                    fontSize: 13,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  item['kode']?.toString() ?? '-',

                  style: const TextStyle(
                    color: AdminDashboard.textGrey,

                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  item['tanggal']?.toString() ?? '-',

                  style: const TextStyle(
                    color: AdminDashboard.textGrey,

                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                formatRupiah(nominal),

                style: const TextStyle(
                  color: AdminDashboard.textDark,

                  fontSize: 12,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                decoration: BoxDecoration(
                  color: selesai
                      ? Colors.green.withValues(alpha: 0.10)
                      : Colors.orange.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  status,

                  style: TextStyle(
                    color: selesai
                        ? Colors.green.shade700
                        : Colors.orange.shade700,

                    fontSize: 9,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LINE CHART
// ============================================================

class _LineChartPainter extends CustomPainter {
  final List<dynamic> data;

  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF2E8B72)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = const Color(0xFF2E8B72)
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    // ============================================================
    // GRID
    // ============================================================

    for (int i = 0; i < 4; i++) {
      final y = (size.height / 4) * i;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (data.isEmpty) {
      return;
    }

    // ============================================================
    // DATA GRAFIK
    // ============================================================

    final values = data.map<double>((item) {
      return double.tryParse(item['nilai']?.toString() ?? '0') ?? 0;
    }).toList();

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    if (maxValue <= 0) {
      return;
    }

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : (size.width / (values.length - 1)) * i;

      final y = size.height - ((values[i] / maxValue) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, paintPoint);
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return true;
  }
}

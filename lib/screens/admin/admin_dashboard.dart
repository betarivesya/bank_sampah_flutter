import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const Color darkGreen = Color(0xFF263B34);
  static const Color primaryGreen = Color(0xFF276F58);
  static const Color background = Color(0xFFEDF1EF);
  static const Color textDark = Color(0xFF263B34);
  static const Color textGrey = Color(0xFF7B8783);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ============================================================
  // DATA DASHBOARD
  // ============================================================

  bool isLoading = true;

  int nasabahAktif = 0;
  double kasBankSampah = 0;
  double totalSaldoNasabah = 0;
  double nilaiSetoran = 0;
  double totalSampahTerkumpul = 0;

  int totalPetugasAktif = 0;
  int penarikanPending = 0;
  int transaksiDisetujui = 0;

  List<dynamic> grafikSetoran = [];
  List<dynamic> grafikBeratJenis = [];
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

      debugPrint('DATA DASHBOARD ADMIN: $data');
      debugPrint('TOTAL SAMPAH API: ${data['total_sampah_terkumpul']}');

      debugPrint('TOTAL PETUGAS AKTIF API: ${data['total_petugas_aktif']}');

      if (!mounted) return;

      setState(() {
        nasabahAktif =
            int.tryParse(data['nasabah_aktif']?.toString() ?? '0') ?? 0;

        totalPetugasAktif =
            int.tryParse(data['total_petugas_aktif']?.toString() ?? '0') ?? 0;

        kasBankSampah =
            double.tryParse(data['kas_bank_sampah']?.toString() ?? '0') ?? 0;

        totalSaldoNasabah =
            double.tryParse(data['total_saldo_nasabah']?.toString() ?? '0') ??
            0;

        totalSampahTerkumpul =
            double.tryParse(
              data['total_sampah_terkumpul']?.toString() ?? '0',
            ) ??
            0;

        nilaiSetoran =
            double.tryParse(data['nilai_setoran']?.toString() ?? '0') ?? 0;

        penarikanPending =
            int.tryParse(data['penarikan_pending']?.toString() ?? '0') ?? 0;

        transaksiDisetujui =
            int.tryParse(data['transaksi_disetujui']?.toString() ?? '0') ?? 0;

        grafikSetoran = List<dynamic>.from(data['grafik_setoran'] ?? []);

        grafikBeratJenis = List<dynamic>.from(data['grafik_berat_jenis'] ?? [])
          ..sort((a, b) {
            final beratA =
                double.tryParse(a['total_berat']?.toString() ?? '0') ?? 0.0;

            final beratB =
                double.tryParse(b['total_berat']?.toString() ?? '0') ?? 0.0;

            return beratB.compareTo(beratA);
          });

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
  // HEADER DASHBOARD
  // ============================================================

  Widget _buildDashboardHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Admin',
          style: TextStyle(
            color: AdminDashboard.darkGreen,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Ringkasan aktivitas Bank Sampah Griya Ayu',
          style: TextStyle(color: AdminDashboard.darkGreen, fontSize: 12),
        ),
      ],
    );
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
              _buildDashboardHeader(),

              const SizedBox(height: 16),

              if (!isLoading && penarikanPending > 0) ...[
                _buildPendingAlert(),
                const SizedBox(height: 20),
              ],

              _buildStatistics(),

              const SizedBox(height: 20),

              _buildActivityStatistics(),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ringkasan Utama'),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          children: [
            _statisticCard(
              title: 'Kas Bank Sampah',
              value: isLoading ? '...' : formatRupiah(kasBankSampah),
              icon: Icons.account_balance_wallet_outlined,
            ),

            _statisticCard(
              title: 'Total Saldo Nasabah',
              value: isLoading ? '...' : formatRupiah(totalSaldoNasabah),
              icon: Icons.people_outline_rounded,
            ),

            _statisticCard(
              title: 'Sampah Terkumpul',
              value: isLoading
                  ? '...'
                  : '${totalSampahTerkumpul.toStringAsFixed(0)} gram',
              icon: Icons.recycling_outlined,
            ),

            _statisticCard(
              title: 'Total Nilai Setoran',
              value: isLoading ? '...' : formatRupiah(nilaiSetoran),
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIK AKTIVITAS
  // ============================================================

  Widget _buildActivityStatistics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          _buildSectionTitle('Aktivitas Bank Sampah'),
          const SizedBox(height: 16),

          _activityRow(
            title: 'Nasabah Aktif',
            value: nasabahAktif.toString(),
            icon: Icons.people_outline,
          ),

          const Divider(height: 20),

          _activityRow(
            title: 'Petugas Aktif',
            value: totalPetugasAktif.toString(),
            icon: Icons.badge_outlined,
          ),

          const Divider(height: 20),

          _activityRow(
            title: 'Setoran Berhasil',
            value: transaksiDisetujui.toString(),
            icon: Icons.recycling_outlined,
          ),
        ],
      ),
    );
  }

  Widget _activityRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: AdminDashboard.primaryGreen, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AdminDashboard.textGrey,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AdminDashboard.textDark,
          ),
        ),
      ],
    );
  }

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

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AdminDashboard.textGrey,
                fontSize: 13,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              color: AdminDashboard.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        border: Border.all(color: const Color(0xFFFFB74D)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFFE58A00),
            size: 23,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perlu Perhatian',
                  style: TextStyle(
                    color: Color(0xFF9A5B00),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$penarikanPending pengajuan penarikan menunggu validasi.',
                  style: const TextStyle(
                    color: Color(0xFF8A6A3D),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          const Icon(Icons.chevron_right_rounded, color: Color(0xFFE58A00)),
        ],
      ),
    );
  }

  // ============================================================
  // GRAFIK DASHBOARD
  // ============================================================
  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartCard(
          title: 'Nilai Setoran per Bulan',
          subtitle: DateTime.now().year.toString(),
          chart: CustomPaint(
            painter: _BarChartPainter(grafikSetoran),
            child: const SizedBox.expand(),
          ),
        ),

        const SizedBox(height: 16),

        _buildChartCard(
          title: 'Jumlah Berat Sampah per Jenis',
          subtitle: 'Berat dalam kg',
          chart: _buildWeightChart(),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget chart,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              color: AdminDashboard.textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              color: AdminDashboard.textDark,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  // ============================================================
  // GRAFIK BERAT SAMPAH PER JENIS
  // ============================================================

  Widget _buildWeightChart() {
    if (grafikBeratJenis.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data berat sampah.',
          style: TextStyle(color: AdminDashboard.textGrey, fontSize: 12),
        ),
      );
    }

    final values = grafikBeratJenis.map<double>((item) {
      return double.tryParse(item['total_berat']?.toString() ?? '0') ?? 0;
    }).toList();

    final maxBerat = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: grafikBeratJenis.length,
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(grafikBeratJenis[index]);

        final nama = item['nama_sampah']?.toString() ?? '-';
        final berat = values[index];

        final progress = maxBerat > 0 ? berat / maxBerat : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              SizedBox(
                width: 85,
                child: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminDashboard.textDark,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFEEF1EE),
                    color: AdminDashboard.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 55,
                child: Text(
                  '${berat.toStringAsFixed(2)} gram / 1 ton',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AdminDashboard.textGrey,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                      ? Color(0xFF298357).withValues(alpha: 0.10)
                      : Color(0xFFD88916).withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  status,

                  style: TextStyle(
                    color: selesai ? Color(0xFF166534) : Color(0xFFD88916),

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
class _BarChartPainter extends CustomPainter {
  final List<dynamic> data;

  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Color(0xFF71847F).withValues(alpha: 0.15)
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = AdminDashboard.primaryGreen
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (data.isEmpty) return;

    final values = data.map<double>((item) {
      return double.tryParse(item['nilai']?.toString() ?? '0') ?? 0;
    }).toList();

    final maxValue = values.fold<double>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );

    if (maxValue <= 0) return;

    const gap = 5.0;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;

    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxValue) * (size.height - 15);
      final left = i * (barWidth + gap);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(3),
      );

      canvas.drawRRect(rect, barPaint);

      final bulan = int.tryParse(data[i]['bulan']?.toString() ?? '') ?? 0;

      final label = TextPainter(
        text: TextSpan(
          text: [
            '',
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agu',
            'Sep',
            'Okt',
            'Nov',
            'Des',
          ][bulan.clamp(0, 12)],
          style: const TextStyle(color: Colors.black, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      label.paint(
        canvas,
        Offset(left + (barWidth - label.width) / 2, size.height - label.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}

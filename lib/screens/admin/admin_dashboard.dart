import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color background = Color(0xFFF5F7F8);
  static const Color textDark = Color(0xFF24413D);
  static const Color textGrey = Color(0xFF7B8A89);

  String formatRupiah(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    return 'Rp${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
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

  // ==========================================================
  // HERO / WELCOME CARD
  // ==========================================================

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [darkGreen, primaryGreen]),
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

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ==========================================================
  // STATISTICS
  // ==========================================================

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
          value: '6',
          icon: Icons.people_outline_rounded,
        ),

        _statisticCard(
          title: 'Nilai Setoran',
          value: 'Rp143.500',
          icon: Icons.payments_outlined,
        ),

        _statisticCard(
          title: 'Saldo Nasabah',
          value: 'Rp1.848.000',
          icon: Icons.account_balance_wallet_outlined,
        ),

        _statisticCard(
          title: 'Menunggu Validasi',
          value: '3',
          icon: Icons.pending_actions_outlined,
        ),

        _statisticCard(
          title: 'Penarikan Pending',
          value: '3',
          icon: Icons.money_outlined,
        ),

        _statisticCard(
          title: 'Transaksi Disetujui',
          value: '2',
          icon: Icons.check_circle_outline_rounded,
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
                  color: primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryGreen, size: 19),
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
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(title, style: const TextStyle(color: textGrey, fontSize: 11)),
        ],
      ),
    );
  }

  // ==========================================================
  // CHART
  // ==========================================================

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
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text('2026', style: TextStyle(color: textGrey, fontSize: 12)),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _LineChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TRANSAKSI TERBARU
  // ==========================================================

  Widget _buildLatestTransactions() {
    final transactions = [
      {
        'kode': 'TRX-20240901-001',
        'nama': 'Sri Rahayu',
        'tanggal': '01 Sep 2026',
        'nominal': 19750,
        'status': 'Menunggu',
      },
      {
        'kode': 'TRX-20240905-002',
        'nama': 'Sri Rahayu',
        'tanggal': '05 Sep 2026',
        'nominal': 22000,
        'status': 'Menunggu',
      },
      {
        'kode': 'TRX-20240908-003',
        'nama': 'Budi Santoso',
        'tanggal': '08 Sep 2026',
        'nominal': 15500,
        'status': 'Selesai',
      },
    ];

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
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          ...transactions.map((item) => _transactionItem(item)),
        ],
      ),
    );
  }

  Widget _transactionItem(Map<String, dynamic> item) {
    final bool selesai = item['status'] == 'Selesai';

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
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.recycling_outlined,
              color: primaryGreen,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'],
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  item['kode'],
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),

                const SizedBox(height: 3),

                Text(
                  item['tanggal'],
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(item['nominal']),
                style: const TextStyle(
                  color: textDark,
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
                  item['status'],
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
// LINE CHART PAINTER
// ============================================================

class _LineChartPainter extends CustomPainter {
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

    const values = [0.35, 0.50, 0.42, 0.68, 0.58, 0.78, 0.65];

    for (int i = 0; i < 4; i++) {
      final y = (size.height / 4) * i;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (size.width / (values.length - 1)) * i;

      final y = size.height - (values[i] * size.height);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

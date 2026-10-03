import 'package:flutter/material.dart';

import '../../app_styles.dart';
import 'admin_drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedMenu = 'dashboard';

  void _selectMenu(String menu) {
    setState(() {
      _selectedMenu = menu;
    });

    if (menu != 'dashboard') {
      String message;

      switch (menu) {
        case 'sampah':
          message = 'Menu Kelola Sampah akan segera dibuat.';
          break;

        case 'pengguna':
          message = 'Menu Manajemen Pengguna akan segera dibuat.';
          break;

        case 'laporan':
          message = 'Menu Laporan akan segera dibuat.';
          break;

        default:
          message = 'Menu belum tersedia.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      setState(() {
        _selectedMenu = 'dashboard';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ==========================================
      // DRAWER / SIDEBAR
      // ==========================================
      drawer: AdminDrawer(
        selectedMenu: _selectedMenu,
        onMenuSelected: _selectMenu,
      ),

      // ==========================================
      // APP BAR
      // ==========================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,

        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Admin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Bank Sampah Griya Ayu',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
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
              children: [
                const Icon(Icons.notifications_outlined, size: 24),

                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
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

      // ==========================================
      // BODY
      // ==========================================
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data dashboard diperbarui.')),
          );
        },

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildAttentionCard(),

            const SizedBox(height: 16),

            _buildStatistics(),

            const SizedBox(height: 20),

            _buildChartSection(),

            const SizedBox(height: 20),

            _buildLatestTransactions(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PERLU PERHATIAN
  // ==========================================

  Widget _buildAttentionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8B3),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE09B00),
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perlu Perhatian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A5A00),
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  '3 transaksi menunggu validasi',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A6848)),
                ),

                SizedBox(height: 3),

                Text(
                  '3 penarikan menunggu diproses',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A6848)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STATISTIK
  // ==========================================

  Widget _buildStatistics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.people_outline,
                title: 'Nasabah Aktif',
                value: '6',
                subtitle: 'nasabah terdaftar',
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildStatisticCard(
                icon: Icons.payments_outlined,
                title: 'Nilai Setoran',
                value: 'Rp143.500',
                subtitle: 'total nilai transaksi',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Saldo Nasabah',
                value: 'Rp1.848.000',
                subtitle: 'saldo tersimpan',
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildStatisticCard(
                icon: Icons.pending_actions_outlined,
                title: 'Menunggu Validasi',
                value: '3',
                subtitle: 'perlu divalidasi',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                icon: Icons.arrow_downward_rounded,
                title: 'Penarikan Pending',
                value: '3',
                subtitle: 'perlu diproses',
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildStatisticCard(
                icon: Icons.check_circle_outline,
                title: 'Transaksi Disetujui',
                value: '2',
                subtitle: 'sudah divalidasi',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRAFIK
  // ==========================================

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Setoran',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nilai Setoran per Bulan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBar('Apr', 0.55),
                    _buildBar('Mei', 0.72),
                    _buildBar('Jun', 0.42),
                    _buildBar('Jul', 0.88),
                    _buildBar('Agu', 0.78),
                    _buildBar('Sep', 0.60),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jumlah Transaksi per Bulan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 100,
                child: CustomPaint(
                  painter: _LineChartPainter(),
                  child: const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Mei',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  Text(
                    'Jun',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  Text(
                    'Jul',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  Text(
                    'Agu',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  Text(
                    'Sep',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(String month, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: 105 * heightFactor,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),

        const SizedBox(height: 6),

        Text(month, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  // ==========================================
  // TRANSAKSI TERBARU
  // ==========================================

  Widget _buildLatestTransactions() {
    final transactions = [
      {
        'nomor': 'TRX-20240901-001',
        'nasabah': 'Sri Rahayu',
        'tanggal': '01 Sep 2026',
        'nilai': 'Rp19.750',
        'status': 'Menunggu',
      },
      {
        'nomor': 'TRX-20240905-002',
        'nasabah': 'Sri Rahayu',
        'tanggal': '05 Sep 2026',
        'nilai': 'Rp22.000',
        'status': 'Menunggu',
      },
      {
        'nomor': 'TRX-20240908-003',
        'nasabah': 'Budi Santoso',
        'tanggal': '08 Sep 2026',
        'nilai': 'Rp15.500',
        'status': 'Selesai',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Halaman transaksi akan dibuat nanti.'),
                  ),
                );
              },
              child: const Text(
                'Lihat semua',
                style: TextStyle(fontSize: 11, color: AppColors.primary),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: transactions.map((transaction) {
              final bool isWaiting = transaction['status'] == 'Menunggu';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.recycling_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction['nomor']!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            transaction['nasabah']!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            transaction['tanggal']!,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          transaction['nilai']!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isWaiting
                                ? const Color(0xFFFFF0DC)
                                : const Color(0xFFE8F6EF),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            transaction['status']!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isWaiting
                                  ? const Color(0xFFC47A00)
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// LINE CHART PAINTER
// ==========================================

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final points = [
      Offset(size.width * 0.08, size.height * 0.70),
      Offset(size.width * 0.28, size.height * 0.55),
      Offset(size.width * 0.48, size.height * 0.42),
      Offset(size.width * 0.68, size.height * 0.25),
      Offset(size.width * 0.88, size.height * 0.38),
    ];

    // Grid
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 5;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line
    final path = Path();

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Points
    for (final point in points) {
      canvas.drawCircle(point, 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

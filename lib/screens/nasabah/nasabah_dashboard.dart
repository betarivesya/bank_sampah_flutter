import 'package:flutter/material.dart';

import 'riwayat_transaksi_screen.dart';
import 'penarikan_screen.dart';
import 'harga_sampah_screen.dart';
import 'profil_screen.dart';
import '../auth/login_screen.dart';
import 'notifikasi_screen.dart';

class NasabahDashboard extends StatefulWidget {
  const NasabahDashboard({super.key});

  @override
  State<NasabahDashboard> createState() => _NasabahDashboardState();
}

class _NasabahDashboardState extends State<NasabahDashboard> {
  int _selectedIndex = 0;

  // =========================
  // DATA DUMMY NASABAH
  // =========================
  final String namaNasabah = 'Nasabah';
  final String nomorAnggota = 'BSA-0001';

  final double saldo = 150000;
  final int totalSetoran = 12;
  final double totalSampah = 38.50;
  final double totalPendapatan = 785000;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar'),
          content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

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

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 1:
        return const RiwayatTransaksiScreen();

      case 2:
        return const PenarikanScreen();

      case 3:
        return const HargaSampahScreen();

      default:
        return _buildHome();
    }
  }

  // =========================
  // HOME / DASHBOARD
  // =========================
  Widget _buildHome() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),

                  const SizedBox(height: 16),

                  _buildBalanceCard(),

                  const SizedBox(height: 16),

                  _buildStatistics(),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    title: 'Transaksi Terbaru',
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildTransactionCard(),

                  const SizedBox(height: 20),

                  _buildWithdrawalCard(),

                  const SizedBox(height: 20),

                  _buildLatestWithdrawal(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HEADER
  // =========================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          // LOGO
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Color(0xFF167A63),
              size: 25,
            ),
          ),

          const SizedBox(width: 10),

          // NAMA APLIKASI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Bank Sampah',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                Text(
                  'Griya Ayu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF167A63),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // NOTIFIKASI
          _buildHeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: _showNotifications,
            showDot: true,
          ),

          const SizedBox(width: 8),

          // LOGOUT
          _buildHeaderButton(icon: Icons.logout_rounded, onTap: _logout),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return Stack(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: Icon(icon, color: const Color(0xFF172033), size: 21),
            ),
          ),
        ),

        if (showDot)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A3D),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // =========================
  // PROFILE CARD
  // =========================
  Widget _buildProfileCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7ECEA)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF2E9B7D),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaNasabah,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nomorAnggota,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // =========================
  // SALDO - GRADIENT
  // =========================
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176B59), Color(0xFF2E9277)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B59).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Saldo Saat Ini',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _formatRupiah(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Saldo yang tersedia',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Tarik Saldo  →',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // STATISTICS
  // =========================
  Widget _buildStatistics() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildStatisticCard(
          title: 'Total Setoran',
          value: '$totalSetoran',
          subtitle: 'Seluruh transaksi setoran',
          icon: Icons.recycling_rounded,
          iconColor: const Color(0xFF3B82F6),
          backgroundColor: const Color(0xFFEFF5FF),
        ),
        _buildStatisticCard(
          title: 'Total Sampah',
          value: '${totalSampah.toStringAsFixed(2)} kg',
          subtitle: 'Total berat sampah',
          icon: Icons.delete_outline_rounded,
          iconColor: const Color(0xFFF28C28),
          backgroundColor: const Color(0xFFFFF4E7),
        ),
        _buildStatisticCard(
          title: 'Total Pendapatan',
          value: _formatRupiah(totalPendapatan),
          subtitle: 'Hasil seluruh setoran',
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFF16805F),
          backgroundColor: const Color(0xFFEAF7F1),
        ),
        _buildStatisticCard(
          title: 'Tahun Aktif',
          value: '2026',
          subtitle: 'Statistik tahun ini',
          icon: Icons.calendar_month_outlined,
          iconColor: const Color(0xFF8B5CF6),
          backgroundColor: const Color(0xFFF3EEFF),
        ),
      ],
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // =========================
  // SECTION HEADER
  // =========================
  Widget _buildSectionHeader({required String title, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text(
              'Lihat semua',
              style: TextStyle(
                color: Color(0xFF167A63),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // =========================
  // TRANSACTION
  // =========================
  Widget _buildTransactionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        children: [
          _buildTransactionItem(
            code: 'ST-00012',
            date: '28 September 2026',
            weight: '3,5 kg',
            amount: 17500,
            status: 'Selesai',
          ),

          const Divider(height: 24),

          _buildTransactionItem(
            code: 'ST-00011',
            date: '20 September 2026',
            weight: '5 kg',
            amount: 25000,
            status: 'Selesai',
          ),

          const Divider(height: 24),

          _buildTransactionItem(
            code: 'ST-00010',
            date: '12 September 2026',
            weight: '2 kg',
            amount: 10000,
            status: 'Selesai',
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String code,
    required String date,
    required String weight,
    required double amount,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Color(0xFF16805F),
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$date • $weight',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+ ${_formatRupiah(amount)}',
              style: const TextStyle(
                color: Color(0xFF16805F),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              status,
              style: const TextStyle(color: Color(0xFF16805F), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  // =========================
  // WITHDRAWAL CTA
  // =========================
  Widget _buildWithdrawalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF195E4F), Color(0xFF2C806B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Butuh uang dari saldo?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ajukan penarikan saldo tabungan Anda melalui menu penarikan.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF195E4F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ajukan Penarikan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // LATEST WITHDRAWAL
  // =========================
  Widget _buildLatestWithdrawal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Penarikan Terbaru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: const Text(
                  'Riwayat',
                  style: TextStyle(color: Color(0xFF167A63), fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.grey.shade400,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada pengajuan penarikan.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // RUPIAH FORMAT
  // =========================
  String _formatRupiah(double value) {
    final formatted = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');

    return 'Rp $formatted';
  }

  // =========================
  // BOTTOM NAVIGATION
  // =========================
  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE0F2EB),
      elevation: 8,
      height: 68,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Transaksi',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Penarikan',
        ),
        NavigationDestination(
          icon: Icon(Icons.price_change_outlined),
          selectedIcon: Icon(Icons.price_change_rounded),
          label: 'Harga Sampah',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}

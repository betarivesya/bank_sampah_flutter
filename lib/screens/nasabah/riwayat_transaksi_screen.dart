import 'package:flutter/material.dart';

import '../../app_styles.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  final List<_TransactionItem> _transactions = const [
    _TransactionItem(
      icon: Icons.recycling,
      title: 'Setoran Sampah',
      date: '20 September 2026',
      amount: '+ Rp20.000',
      status: 'Selesai',
      isIncome: true,
      type: 'Setoran',
    ),
    _TransactionItem(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Penarikan Saldo',
      date: '18 September 2026',
      amount: '- Rp10.000',
      status: 'Terverifikasi',
      isIncome: false,
      type: 'Penarikan',
    ),
    _TransactionItem(
      icon: Icons.recycling,
      title: 'Setoran Sampah',
      date: '15 September 2026',
      amount: '+ Rp15.000',
      status: 'Selesai',
      isIncome: true,
      type: 'Setoran',
    ),
  ];

  String _selectedFilter = 'Semua';

  List<_TransactionItem> get _filteredTransactions {
    if (_selectedFilter == 'Semua') {
      return _transactions;
    }

    return _transactions.where((item) => item.type == _selectedFilter).toList();
  }

  int get _totalSetoran {
    return _transactions.where((item) => item.type == 'Setoran').length;
  }

  int get _totalPenarikan {
    return _transactions.where((item) => item.type == 'Penarikan').length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==========================================
          // JUDUL
          // ==========================================

          const Text(
            'Lihat seluruh riwayat setoran dan penarikan saldo Anda.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 18),

          // ==========================================
          // STATISTIK
          // ==========================================
          Row(
            children: [
              Expanded(
                child: _buildStatisticCard(
                  title: 'Total Transaksi Setoran',
                  value: _totalSetoran.toString(),
                  subtitle: 'Jumlah transaksi setoran',
                  icon: Icons.recycling,
                  iconColor: AppColors.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildStatisticCard(
                  title: 'Total Penarikan',
                  value: _totalPenarikan.toString(),
                  subtitle: 'Jumlah pengajuan penarikan',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ==========================================
          // FILTER TRANSAKSI
          // ==========================================
          const Text(
            'Filter Transaksi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,

                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                ),

                items: const ['Semua', 'Setoran', 'Penarikan'].map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'Setoran'
                              ? Icons.arrow_upward
                              : value == 'Penarikan'
                              ? Icons.arrow_downward
                              : Icons.filter_list,
                          size: 18,
                          color: AppColors.primary,
                        ),

                        const SizedBox(width: 10),

                        Text(value, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // JUDUL DAFTAR TRANSAKSI
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Transaksi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              Text(
                '${filteredTransactions.length} transaksi',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ==========================================
          // LIST TRANSAKSI
          // ==========================================
          if (filteredTransactions.isEmpty)
            _buildEmptyState()
          else
            ...filteredTransactions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TransactionCard(
                  icon: item.icon,
                  title: item.title,
                  date: item.date,
                  amount: item.amount,
                  status: item.status,
                  isIncome: item.isIncome,
                ),
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ==========================================
  // STATISTIC CARD
  // ==========================================

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 45,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 12),

          const Text(
            'Tidak ada transaksi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Tidak ada transaksi pada filter yang dipilih.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// MODEL TRANSAKSI
// ==================================================

class _TransactionItem {
  final IconData icon;
  final String title;
  final String date;
  final String amount;
  final String status;
  final bool isIncome;
  final String type;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.isIncome,
    required this.type,
  });
}

// ==================================================
// CARD TRANSAKSI
// ==================================================

class _TransactionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String amount;
  final String status;
  final bool isIncome;

  const _TransactionCard({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ICON
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: isIncome ? AppColors.primary : Colors.orange,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          // INFORMASI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isIncome
                          ? AppColors.primary
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // NOMINAL
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.primary : Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

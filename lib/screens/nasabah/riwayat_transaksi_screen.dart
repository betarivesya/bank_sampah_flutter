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
      icon: Icons.payments_outlined,
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

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Riwayat Transaksi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Daftar transaksi yang dilakukan',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                icon: const Icon(
                  Icons.filter_alt_outlined,
                  color: AppColors.primary,
                ),
                items: const ['Semua', 'Setoran', 'Penarikan']
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
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
          const SizedBox(height: 18),
          if (filteredTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Tidak ada transaksi pada filter ini.'),
              ),
            )
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
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 25),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
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
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.primary : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

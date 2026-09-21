import 'package:flutter/material.dart';

import '../../app_styles.dart';

class RiwayatTransaksiScreen extends StatelessWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

          const SizedBox(height: 24),

          // =========================
          // CONTOH TRANSAKSI SETORAN
          // =========================
          _TransactionCard(
            icon: Icons.recycling,
            title: 'Setoran Sampah',
            date: '20 September 2026',
            amount: '+ Rp20.000',
            status: 'Selesai',
            isIncome: true,
          ),

          const SizedBox(height: 12),

          // =========================
          // CONTOH TRANSAKSI PENARIKAN
          // =========================
          _TransactionCard(
            icon: Icons.payments_outlined,
            title: 'Penarikan Saldo',
            date: '18 September 2026',
            amount: '- Rp10.000',
            status: 'Terverifikasi',
            isIncome: false,
          ),

          const SizedBox(height: 12),

          _TransactionCard(
            icon: Icons.recycling,
            title: 'Setoran Sampah',
            date: '15 September 2026',
            amount: '+ Rp15.000',
            status: 'Selesai',
            isIncome: true,
          ),
        ],
      ),
    );
  }
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

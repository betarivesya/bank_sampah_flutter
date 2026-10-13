import 'package:flutter/material.dart';

import '../models/jenis_sampah_model.dart';
import '../app_styles.dart';

class JenisSampahCard extends StatelessWidget {
  final JenisSampah item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAturHarga;

  const JenisSampahCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onAturHarga,
  });

  @override
  Widget build(BuildContext context) {
    final bool adaHarga = item.idHarga != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardBoxDecoration,
      child: Row(
        children: [
          // Icon sampah
          CircleAvatar(
            backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
            child: const Icon(Icons.recycling, color: AppColors.primary),
          ),

          const SizedBox(width: 12),

          // Informasi jenis sampah dan harga
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.namaSampah, style: AppTextStyles.title),

                const SizedBox(height: 4),

                Text(
                  adaHarga
                      ? 'Rp ${item.hargaPerKg.toStringAsFixed(0)} / kg'
                      : 'Harga belum diatur',
                  style: adaHarga
                      ? AppTextStyles.price
                      : AppTextStyles.subtitle,
                ),
              ],
            ),
          ),

          // Tombol atur harga
          IconButton(
            icon: const Icon(Icons.attach_money, color: Colors.green),
            tooltip: 'Atur Harga',
            onPressed: onAturHarga,
          ),

          // Tombol edit
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: 'Edit Jenis Sampah',
            onPressed: onEdit,
          ),

          // Tombol hapus
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus Jenis Sampah',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

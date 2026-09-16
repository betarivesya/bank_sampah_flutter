// lib/widgets/jenis_sampah_card.dart
import 'package:flutter/material.dart';
import '../models/jenis_sampah_model.dart';
import '../app_styles.dart';

class JenisSampahCard extends StatelessWidget {
  final JenisSampah item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAturHarga;

  const JenisSampahCard({
    Key? key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onAturHarga,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool adaHarga = item.listHarga.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardBoxDecoration,
      child: Row(
        children: [
          // Icon Avatar Bulat Samping
          CircleAvatar(
            backgroundColor: AppColors.secondary.withOpacity(0.2),
            child: const Icon(Icons.recycling, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          // Info Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.namaSampah, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                  adaHarga
                      ? 'Rp ${item.listHarga.last.hargaPerKg} / kg'
                      : 'Harga belum diatur',
                  style: adaHarga
                      ? AppTextStyles.price
                      : AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          // Tombol-tombol Aksi
          IconButton(
            icon: const Icon(Icons.attach_money, color: Colors.green),
            tooltip: 'Atur Harga',
            onPressed: onAturHarga,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
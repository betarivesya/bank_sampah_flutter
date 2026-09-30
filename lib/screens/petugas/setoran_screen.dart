import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/app_styles.dart';
import 'package:bank_sampah_flutter/data/petugas_dummy_data.dart';
import 'package:bank_sampah_flutter/models/petugas_model.dart';
import 'package:bank_sampah_flutter/screens/petugas/tambah_setoran_screen.dart';

class SetoranScreen extends StatefulWidget {
  const SetoranScreen({super.key});

  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> {
  Future<void> _tambahSetoran() async {
    final tersimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TambahSetoranScreen()),
    );

    if (tersimpan == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setoran berhasil ditambahkan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = [...PetugasDummyData.setoran]
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Setoran Sampah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: list.isEmpty
          ? const Center(child: Text('Belum ada data setoran.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                return _SetoranCard(item: item);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _tambahSetoran,
        icon: const Icon(Icons.add),
        label: const Text('Setoran Baru'),
      ),
    );
  }
}

class _SetoranCard extends StatelessWidget {
  final DummySetoran item;

  const _SetoranCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardBoxDecoration,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.recycling_outlined,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaNasabah,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.namaSampah} • ${item.beratKg.toStringAsFixed(1)} Kg',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 3),
                Text(
                  tanggalIndonesia(item.tanggal),
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          Text(rupiah(item.total), style: AppTextStyles.price),
        ],
      ),
    );
  }
}

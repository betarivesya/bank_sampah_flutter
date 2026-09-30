import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/app_styles.dart';
import 'package:bank_sampah_flutter/data/petugas_dummy_data.dart';
import 'package:bank_sampah_flutter/models/petugas_model.dart';
import 'package:bank_sampah_flutter/screens/petugas/detail_nasabah_screen.dart';

class NasabahScreen extends StatefulWidget {
  const NasabahScreen({super.key});

  @override
  State<NasabahScreen> createState() => _NasabahScreenState();
}

class _NasabahScreenState extends State<NasabahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _keyword = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DummyNasabah> get _filteredNasabah {
    if (_keyword.isEmpty) {
      return PetugasDummyData.nasabah;
    }

    return PetugasDummyData.nasabah.where((item) {
      return item.nama.toLowerCase().contains(_keyword) ||
          item.noHp.toLowerCase().contains(_keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredNasabah;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Data Nasabah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: TextField(
              controller: _searchController,
              decoration:
                  AppDecorations.inputDecoration(
                    'Cari nama atau nomor HP',
                    icon: Icons.search,
                  ).copyWith(
                    suffixIcon: _keyword.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.clear),
                          ),
                  ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final nasabah = list[index];
                      return _NasabahCard(
                        nasabah: nasabah,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailNasabahScreen(nasabah: nasabah),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NasabahCard extends StatelessWidget {
  final DummyNasabah nasabah;
  final VoidCallback onTap;

  const _NasabahCard({required this.nasabah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardBoxDecoration,
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.secondary.withOpacity(0.25),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nasabah.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(nasabah.noHp, style: AppTextStyles.subtitle),
                    const SizedBox(height: 7),
                    Text(
                      'Saldo ${rupiah(nasabah.saldo)}',
                      style: AppTextStyles.price,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nasabah tidak ditemukan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              'Coba gunakan nama atau nomor HP yang lain.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

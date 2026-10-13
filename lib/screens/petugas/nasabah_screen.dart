import 'package:flutter/material.dart';

import 'package:bank_sampah_flutter/data/petugas_dummy_data.dart';
import 'package:bank_sampah_flutter/models/petugas_model.dart';
import 'package:bank_sampah_flutter/screens/petugas/detail_nasabah_screen.dart';

class NasabahScreen extends StatefulWidget {
  const NasabahScreen({super.key});

  @override
  State<NasabahScreen> createState() => _NasabahScreenState();
}

class _NasabahScreenState extends State<NasabahScreen> {
  // ==========================================================
  // WARNA
  // ==========================================================

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color lightGreen = Color(0xFFE8F5F1);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textDark = Color(0xFF172033);
  // ==========================================================
  // SEARCH
  // ==========================================================

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

  // ==========================================================
  // FILTER NASABAH
  // ==========================================================

  List<DummyNasabah> get _filteredNasabah {
    if (_keyword.isEmpty) {
      return PetugasDummyData.nasabah;
    }

    return PetugasDummyData.nasabah.where((item) {
      return item.nama.toLowerCase().contains(_keyword) ||
          item.noHp.toLowerCase().contains(_keyword);
    }).toList();
  }

  // ==========================================================
  // FORMAT RUPIAH
  // ==========================================================

  String formatRupiah(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final list = _filteredNasabah;

    return Container(
      color: background,
      child: Column(
        children: [
          // ====================================================
          // HEADER SEARCH
          // ====================================================

          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Data Nasabah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Cari nasabah berdasarkan nama atau nomor HP',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),

                const SizedBox(height: 13),

                // SEARCH FIELD
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau nomor HP...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: primaryGreen,
                        size: 22,
                      ),
                      suffixIcon: _keyword.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.grey,
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // JUMLAH NASABAH
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  color: primaryGreen,
                  size: 21,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Daftar Nasabah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length} Nasabah',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ====================================================
          // LIST NASABAH
          // ====================================================
          Expanded(
            child: list.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final nasabah = list[index];

                      return _NasabahCard(
                        nasabah: nasabah,
                        formatRupiah: formatRupiah,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailNasabahScreen(nasabah: nasabah),
                            ),
                          );

                          if (mounted) {
                            setState(() {});
                          }
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

// ============================================================
// CARD NASABAH
// ============================================================

class _NasabahCard extends StatelessWidget {
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color lightGreen = Color(0xFFE8F5F1);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7B8A89);

  final DummyNasabah nasabah;
  final VoidCallback onTap;
  final String Function(num) formatRupiah;

  const _NasabahCard({
    required this.nasabah,
    required this.onTap,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ==================================================
              // AVATAR
              // ==================================================

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: primaryGreen,
                  size: 29,
                ),
              ),

              const SizedBox(width: 13),

              // ==================================================
              // DATA NASABAH
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nasabah.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: textGrey,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            nasabah.noHp,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Text(
                          'Saldo',
                          style: TextStyle(color: textGrey, fontSize: 11),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          formatRupiah(nasabah.saldo),
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // ARROW
              // ==================================================
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: primaryGreen,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.person_search_outlined,
                size: 40,
                color: Color(0xFF2E8B72),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Nasabah tidak ditemukan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF172033),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Coba gunakan nama atau nomor HP yang lain.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7B8A89), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

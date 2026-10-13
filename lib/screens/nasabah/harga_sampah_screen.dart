import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class HargaSampahScreen extends StatefulWidget {
  const HargaSampahScreen({super.key});

  @override
  State<HargaSampahScreen> createState() => _HargaSampahScreenState();
}

class _HargaSampahScreenState extends State<HargaSampahScreen> {
  List<Map<String, dynamic>> hargaSampah = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHargaSampah();
  }

  Future<void> _loadHargaSampah() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getHargaSampah();

      final data = response
          .map((item) {
            final harga = Map<String, dynamic>.from(item as Map);
            final jenis = harga['jenis_sampah'];

            return <String, dynamic>{
              'nama': jenis is Map
                  ? (jenis['nama_sampah'] ?? 'Jenis sampah')
                  : (harga['nama_sampah'] ?? 'Jenis sampah'),
              'harga':
                  double.tryParse((harga['harga_per_kg'] ?? 0).toString()) ?? 0,
              'status': harga['status'],
            };
          })
          .where((item) {
            return item['status'] == 1 || item['status'].toString() == '1';
          })
          .toList();

      if (!mounted) return;

      setState(() {
        hargaSampah = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat harga sampah dari server.';
      });
    }
  }

  IconData _getIcon(String nama) {
    final value = nama.toLowerCase();

    if (value.contains('botol')) {
      return Icons.local_drink_outlined;
    } else if (value.contains('plastik')) {
      return Icons.recycling_outlined;
    } else if (value.contains('kardus')) {
      return Icons.inventory_2_outlined;
    } else if (value.contains('kertas')) {
      return Icons.description_outlined;
    } else if (value.contains('kaca')) {
      return Icons.wine_bar_outlined;
    }

    return Icons.delete_outline;
  }

  String formatRupiah(num value) {
    final harga = value.round().toString();

    return 'Rp ${harga.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.price_change_outlined,
                    color: Color(0xFF167A63),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harga Sampah',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Harga pembelian sampah yang berlaku saat ini',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadHargaSampah,
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh, color: Color(0xFF167A63)),
                ),
              ],
            ),
          ),

          // DAFTAR HARGA
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF167A63)),
                  )
                : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 42,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadHargaSampah,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : hargaSampah.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data harga sampah.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHargaSampah,
                    color: const Color(0xFF167A63),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: hargaSampah.length,
                      itemBuilder: (context, index) {
                        final item = hargaSampah[index];
                        final nama = item['nama'] as String;
                        final harga = item['harga'] as double;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8ECEA)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
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
                                  color: const Color(0xFFEAF7F1),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  _getIcon(nama),
                                  color: const Color(0xFF167A63),
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // NAMA SAMPAH
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nama,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF172033),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Harga per kilogram',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // HARGA
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatRupiah(harga),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF167A63),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '/ kg',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // INFORMASI HARGA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF167A63), size: 18),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Harga sampah dapat berubah sesuai '
                      'kebijakan Bank Sampah Griya Ayu.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF477267),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

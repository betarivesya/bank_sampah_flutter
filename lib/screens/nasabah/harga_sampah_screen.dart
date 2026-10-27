import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class HargaSampahScreen extends StatefulWidget {
  const HargaSampahScreen({super.key});

  @override
  State<HargaSampahScreen> createState() => _HargaSampahScreenState();
}

class _HargaSampahScreenState extends State<HargaSampahScreen> {
  static const Color hijau = Color(0xFF167A63);
  static const Color latar = Color(0xFFF7F9F8);
  static const Color teks = Color(0xFF172033);

  List<Map<String, dynamic>> hargaSampah = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHargaSampah();
  }

  Future<void> _loadHargaSampah() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await ApiService.getHargaSampah();

      final data = response
          .map((item) {
            final harga = Map<String, dynamic>.from(item as Map);
            final jenis = harga['jenis_sampah'];

            return <String, dynamic>{
              'nama': jenis is Map
                  ? (jenis['nama_sampah'] ?? 'Jenis sampah').toString()
                  : (harga['nama_sampah'] ?? 'Jenis sampah').toString(),
              'harga':
                  double.tryParse((harga['harga_per_kg'] ?? 0).toString()) ??
                  0.0,
              'status': harga['status'],
            };
          })
          .where((item) {
            final status = item['status'];
            return status == 1 || status.toString() == '1';
          })
          .toList();

      if (!mounted) return;

      setState(() {
        hargaSampah = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat harga sampah dari server.';
      });
    }
  }

  IconData _getIcon(String nama) {
    final value = nama.toLowerCase();

    if (value.contains('botol')) return Icons.local_drink_outlined;
    if (value.contains('plastik')) return Icons.recycling_outlined;
    if (value.contains('kardus')) return Icons.inventory_2_outlined;
    if (value.contains('kertas')) return Icons.description_outlined;
    if (value.contains('kaca')) return Icons.wine_bar_outlined;

    return Icons.delete_outline;
  }

  String formatRupiah(num value) {
    final angka = value.round().toString();
    final formatted = angka.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latar,
      body: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(color: teks, decoration: TextDecoration.none),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F0),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.price_change_outlined,
                        color: hijau,
                        size: 25,
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
                              color: teks,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Harga pembelian sampah saat ini',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF68756F),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: isLoading ? null : _loadHargaSampah,
                      tooltip: 'Muat ulang',
                      icon: const Icon(Icons.refresh, color: hijau),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildContent()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: hijau, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Harga sampah dapat berubah sesuai kebijakan '
                          'Bank Sampah Griya Ayu.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF477267),
                            height: 1.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: hijau));
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 46,
                color: Color(0xFF89938E),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: teks,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadHargaSampah,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hijau,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hargaSampah.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data harga sampah.',
          style: TextStyle(
            color: Color(0xFF68756F),
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHargaSampah,
      color: hijau,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8ECEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_getIcon(nama), color: hijau, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: teks,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Harga per kilogram',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF89938E),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRupiah(harga),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: hijau,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '/ kg',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF89938E),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

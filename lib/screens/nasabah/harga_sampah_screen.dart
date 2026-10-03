import 'package:flutter/material.dart';

class HargaSampahScreen extends StatelessWidget {
  const HargaSampahScreen({super.key});

  final List<Map<String, dynamic>> hargaSampah = const [
    {
      'nama': 'Botol Plastik',
      'harga': 2000,
      'icon': Icons.local_drink_outlined,
    },
    {'nama': 'Plastik', 'harga': 4000, 'icon': Icons.recycling_outlined},
    {'nama': 'Kardus', 'harga': 3000, 'icon': Icons.inventory_2_outlined},
    {'nama': 'Kertas', 'harga': 2500, 'icon': Icons.description_outlined},
  ];

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ==========================================
          // HEADER
          // ==========================================

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
              ],
            ),
          ),

          // ==========================================
          // DAFTAR HARGA
          // ==========================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: hargaSampah.length,
              itemBuilder: (context, index) {
                final item = hargaSampah[index];

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
                          item['icon'],
                          color: const Color(0xFF167A63),
                          size: 23,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // NAMA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nama'],
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
                            formatRupiah(item['harga']),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF167A63),
                            ),
                          ),

                          const SizedBox(height: 2),

                          const Text(
                            '/ kg',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ==========================================
          // INFORMASI HARGA
          // ==========================================
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

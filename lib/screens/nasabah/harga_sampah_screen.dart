import 'package:flutter/material.dart';

class HargaSampahScreen extends StatelessWidget {
  const HargaSampahScreen({super.key});

  final List<Map<String, dynamic>> hargaSampah = const [
    {'nama': 'Plastik', 'harga': 4000, 'icon': Icons.recycling},
    {'nama': 'Kardus', 'harga': 3000, 'icon': Icons.inventory_2_outlined},
    {
      'nama': 'Botol Plastik',
      'harga': 5000,
      'icon': Icons.local_drink_outlined,
    },
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
                const Column(
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
                    Text(
                      'Harga sampah yang berlaku',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8ECEA)),
                  ),
                  child: Row(
                    children: [
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
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          item['nama'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

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
                            'per kg',
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
        ],
      ),
    );
  }
}

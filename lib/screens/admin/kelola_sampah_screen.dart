import 'package:flutter/material.dart';

import '../../app_styles.dart';

class KelolaSampahScreen extends StatefulWidget {
  const KelolaSampahScreen({super.key});

  @override
  State<KelolaSampahScreen> createState() => _KelolaSampahScreenState();
}

class _KelolaSampahScreenState extends State<KelolaSampahScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'Semua Status';

  // ==========================================================
  // DATA DUMMY
  // Nanti bagian ini bisa diganti dengan data dari API
  // ==========================================================

  final List<Map<String, dynamic>> _dataSampah = [
    {'id': 1, 'jenis': 'Botol Plastik', 'harga': 4000, 'status': 'Aktif'},
    {'id': 2, 'jenis': 'Kardus', 'harga': 3000, 'status': 'Aktif'},
    {'id': 3, 'jenis': 'Kertas', 'harga': 2500, 'status': 'Aktif'},
    {'id': 4, 'jenis': 'Plastik Campur', 'harga': 1500, 'status': 'Nonaktif'},
  ];

  // ==========================================================
  // FORMAT RUPIAH
  // ==========================================================

  String _formatRupiah(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp${buffer.toString()}';
  }

  // ==========================================================
  // FILTER DATA
  // ==========================================================

  List<Map<String, dynamic>> get _filteredData {
    final keyword = _searchController.text.toLowerCase().trim();

    return _dataSampah.where((item) {
      final jenis = item['jenis'].toString().toLowerCase();
      final status = item['status'].toString();

      final cocokSearch = keyword.isEmpty || jenis.contains(keyword);

      final cocokStatus =
          _selectedStatus == 'Semua Status' || status == _selectedStatus;

      return cocokSearch && cocokStatus;
    }).toList();
  }

  // ==========================================================
  // TAMBAH / EDIT DATA
  // ==========================================================

  void _showFormDialog({Map<String, dynamic>? data}) {
    final bool isEdit = data != null;

    final jenisController = TextEditingController(
      text: isEdit ? data['jenis'].toString() : '',
    );

    final hargaController = TextEditingController(
      text: isEdit ? data['harga'].toString() : '',
    );

    String selectedStatus = isEdit ? data['status'].toString() : 'Aktif';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEdit ? 'Edit Sampah' : 'Tambah Jenis Sampah',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24413D),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // JENIS SAMPAH
                    // ==================================================

                    const Text(
                      'Jenis Sampah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: jenisController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Botol Plastik',
                        prefixIcon: const Icon(Icons.recycling_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // HARGA
                    // ==================================================
                    const Text(
                      'Harga per kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: hargaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 4000',
                        prefixText: 'Rp ',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // STATUS
                    // ==================================================
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.toggle_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'Nonaktif',
                          child: Text('Nonaktif'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ========================================================
              // BUTTON
              // ========================================================
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    final jenis = jenisController.text.trim();

                    final hargaText = hargaController.text.trim();

                    if (jenis.isEmpty || hargaText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jenis sampah dan harga wajib diisi.'),
                        ),
                      );

                      return;
                    }

                    final harga = int.tryParse(hargaText);

                    if (harga == null || harga <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Harga harus berupa angka yang valid.'),
                        ),
                      );

                      return;
                    }

                    setState(() {
                      if (isEdit) {
                        final index = _dataSampah.indexWhere(
                          (item) => item['id'] == data['id'],
                        );

                        if (index != -1) {
                          _dataSampah[index] = {
                            'id': data['id'],
                            'jenis': jenis,
                            'harga': harga,
                            'status': selectedStatus,
                          };
                        }
                      } else {
                        final newId = _dataSampah.isEmpty
                            ? 1
                            : _dataSampah
                                      .map((item) => item['id'] as int)
                                      .reduce((a, b) => a > b ? a : b) +
                                  1;

                        _dataSampah.add({
                          'id': newId,
                          'jenis': jenis,
                          'harga': harga,
                          'status': selectedStatus,
                        });
                      }
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Data sampah berhasil diperbarui.'
                              : 'Jenis sampah berhasil ditambahkan.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // HAPUS DATA
  // ==========================================================

  void _showDeleteDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // ICON WARNING
              // ==================================================

              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Hapus Data?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24413D),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Yakin ingin menghapus harga sampah ini? '
                'Data harga yang dihapus tidak dapat digunakan '
                'untuk perhitungan setoran berikutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _dataSampah.removeWhere((item) => item['id'] == data['id']);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data sampah berhasil dihapus.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ya, Lanjutkan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // STATUS BADGE
  // ==========================================================

  Widget _buildStatusBadge(String status) {
    final bool aktif = status == 'Aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: aktif
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: aktif ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================================
  // CARD DATA SAMPAH
  // ==========================================================

  Widget _buildSampahCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // ICON
          // ======================================================

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.recycling_outlined,
              color: Color(0xFF2E8B72),
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // DATA
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['jenis'].toString(),
                  style: const TextStyle(
                    color: Color(0xFF24413D),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${_formatRupiah(item['harga'])} / kg',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 7),

                _buildStatusBadge(item['status'].toString()),
              ],
            ),
          ),

          // ======================================================
          // ACTION
          // ======================================================
          Row(
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () {
                  _showFormDialog(data: item);
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF2E8B72),
                  size: 21,
                ),
              ),

              IconButton(
                tooltip: 'Hapus',
                onPressed: () {
                  _showDeleteDialog(item);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 21,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final data = _filteredData;

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Jenis Sampah',
                        style: TextStyle(
                          color: Color(0xFF24413D),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Atur jenis dan harga sampah',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    _showFormDialog();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ==================================================
            // SEARCH
            // ==================================================
            TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Cari jenis sampah...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // FILTER STATUS
            // ==================================================
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                prefixIcon: const Icon(Icons.filter_list_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Semua Status',
                  child: Text('Semua Status'),
                ),
                DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                DropdownMenuItem(value: 'Nonaktif', child: Text('Nonaktif')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedStatus = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // JUMLAH DATA
            // ==================================================
            Row(
              children: [
                const Text(
                  'Daftar Sampah',
                  style: TextStyle(
                    color: Color(0xFF24413D),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.length}',
                    style: const TextStyle(
                      color: Color(0xFF2E8B72),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // LIST DATA
            // ==================================================
            if (data.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 45,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Data tidak ditemukan',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...data.map((item) => _buildSampahCard(item)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

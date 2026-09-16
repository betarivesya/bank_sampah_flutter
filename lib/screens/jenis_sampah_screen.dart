import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/services/api_service.dart';
import 'package:bank_sampah_flutter/models/jenis_sampah_model.dart';

class JenisSampahScreen extends StatefulWidget {
  const JenisSampahScreen({Key? key}) : super(key: key);

  @override
  State<JenisSampahScreen> createState() => _JenisSampahScreenState();
}

class _JenisSampahScreenState extends State<JenisSampahScreen> {
  final TextEditingController _tambahController = TextEditingController();
  late Future<List<JenisSampah>> _jenisSampahFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Fungsi khusus untuk memicu reload data dari API
  void _refreshData() {
    setState(() {
      _jenisSampahFuture = ApiService.getJenisSampah();
    });
  }

  // 1. Pop-up Dialog untuk Edit Nama Sampah
  void _showEditDialog(JenisSampah item) {
    TextEditingController editController =
        TextEditingController(text: item.namaSampah);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Jenis Sampah', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          decoration: AppStyles.inputDecoration('Nama Jenis Sampah', icon: Icons.edit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (editController.text.isNotEmpty) {
                bool berhasil = await ApiService.updateJenisSampah(
                  item.id,
                  editController.text,
                );
                if (berhasil && mounted) {
                  Navigator.pop(context);
                  _refreshData();
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. Pop-up Dialog Konfirmasi Hapus Data Sampah
  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Data', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              bool berhasil = await ApiService.deleteJenisSampah(id);
              if (berhasil && mounted) {
                Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. Pop-up Dialog Atur / Edit Harga Sampah
  void _showAturHargaDialog(JenisSampah item) {
    TextEditingController hargaInputController = TextEditingController();

    bool adaHarga = item.listHarga.isNotEmpty;
    if (adaHarga) {
      hargaInputController.text = item.listHarga.last.hargaPerKg.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          adaHarga ? 'Edit Harga Sampah' : 'Atur Harga Sampah',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jenis Sampah: ${item.namaSampah}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 12),
            TextField(
              controller: hargaInputController,
              keyboardType: TextInputType.number,
              decoration: AppStyles.inputDecoration('Harga per Kg (Rp)', icon: Icons.payments),
            ),
          ],
        ),
        actions: [
          if (adaHarga)
            TextButton(
              onPressed: () async {
                bool berhasil = await ApiService.deleteHargaSampah(
                    item.listHarga.last.idHarga);
                if (berhasil && mounted) {
                  Navigator.pop(context);
                  _refreshData();
                }
              },
              child: const Text('Hapus Harga',
                  style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              int? harga = int.tryParse(hargaInputController.text);
              if (harga != null) {
                bool berhasil;
                if (adaHarga) {
                  berhasil = await ApiService.updateHargaSampah(
                    item.listHarga.last.idHarga,
                    harga,
                  );
                } else {
                  berhasil = await ApiService.tambahHargaSampah(
                    item.id,
                    harga,
                  );
                }

                if (berhasil && mounted) {
                  Navigator.pop(context);
                  _refreshData();
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Kelola Jenis Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form Tambah Data Jenis Sampah
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tambahController,
                      decoration: AppStyles.inputDecoration(
                        'Nama Jenis Sampah',
                        icon: Icons.recycling,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (_tambahController.text.isNotEmpty) {
                        bool berhasil = await ApiService.tambahJenisSampah(
                            _tambahController.text);
                        if (berhasil) {
                          _tambahController.clear();
                          _refreshData();
                        }
                      }
                    },
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List Data Jenis Sampah + Harga
            Expanded(
              child: FutureBuilder<List<JenisSampah>>(
                future: _jenisSampahFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada data sampah.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  final listData = snapshot.data!;

                  return ListView.builder(
                    itemCount: listData.length,
                    itemBuilder: (context, index) {
                      final item = listData[index];
                      // PANGGIL WIDGET KARTU YANG SUDAH KITA PERCANTIK
                      return SampahItemCard(
                        item: item,
                        onAturHarga: () => _showAturHargaDialog(item),
                        onEdit: () => _showEditDialog(item),
                        onDelete: () => _showDeleteDialog(item.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STYLING / WARNA DITARUH DI BAWAH SINI (Supaya mudah diubah-ubah)
// ============================================================================

class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Hijau Bank Sampah
  static const Color secondary = Color(0xFFA5D6A7); // Hijau Muda
  static const Color background = Color(0xFFF4F6F8); // Abu-abu Terang
}

class AppStyles {
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

// ============================================================================
// WIDGET KARTU TAMPILAN ITEM SAMPAH DITARUH DI BAWAH SINI
// ============================================================================

class SampahItemCard extends StatelessWidget {
  final JenisSampah item;
  final VoidCallback onAturHarga;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SampahItemCard({
    Key? key,
    required this.item,
    required this.onAturHarga,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool adaHarga = item.listHarga.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.secondary.withOpacity(0.3),
          child: const Icon(Icons.delete_outline, color: AppColors.primary),
        ),
        title: Text(
          item.namaSampah,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            adaHarga
                ? 'Rp ${item.listHarga.last.hargaPerKg} / kg'
                : 'Harga: Belum diatur',
            style: TextStyle(
              color: adaHarga ? Colors.green.shade700 : Colors.orange.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol Atur Harga
            IconButton(
              icon: const Icon(Icons.attach_money, color: Colors.green),
              tooltip: 'Atur Harga',
              onPressed: onAturHarga,
            ),
            // Tombol Edit Nama
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: 'Edit Nama',
              onPressed: onEdit,
            ),
            // Tombol Hapus
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/jenis_sampah_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: JenisSampahScreen(),
    );
  }
}

class JenisSampahScreen extends StatefulWidget {
  const JenisSampahScreen({Key? key}) : super(key: key);

  @override
  State<JenisSampahScreen> createState() => _JenisSampahScreenState();
}

class _JenisSampahScreenState extends State<JenisSampahScreen> {
  final TextEditingController _tambahController = TextEditingController();

  // 1. Pop-up Dialog Atur / Edit Harga
  void _showAturHargaDialog(JenisSampah item) {
    TextEditingController hargaInputController = TextEditingController();

    bool adaHarga = item.listHarga.isNotEmpty;
    if (adaHarga) {
      hargaInputController.text = item.listHarga.last.hargaPerKg.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(adaHarga ? 'Edit Harga Sampah' : 'Atur Harga Sampah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jenis Sampah: ${item.namaSampah}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: hargaInputController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga per Kg (Rp)',
                border: OutlineInputBorder(),
              ),
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
                  setState(() {});
                }
              },
              child:
                  const Text('Hapus Harga', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
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
                  setState(() {});
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 2. Pop-up Dialog Edit Nama Jenis Sampah
  void _showEditDialog(JenisSampah item) {
    TextEditingController editController =
        TextEditingController(text: item.namaSampah);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Jenis Sampah'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Nama Jenis Sampah'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.isNotEmpty) {
                bool berhasil = await ApiService.updateJenisSampah(
                  item.id,
                  editController.text,
                );
                if (berhasil && mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 3. Pop-up Dialog Konfirmasi Hapus Data
  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              bool berhasil = await ApiService.deleteJenisSampah(id);
              if (berhasil && mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD Jenis Sampah'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form Tambah Jenis Sampah Baru
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tambahController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Jenis Sampah',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (_tambahController.text.isNotEmpty) {
                      bool berhasil = await ApiService.tambahJenisSampah(
                          _tambahController.text);
                      if (berhasil) {
                        _tambahController.clear();
                        setState(() {});
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daftar List Data dari API
            Expanded(
              child: FutureBuilder<List<JenisSampah>>(
                future: ApiService.getJenisSampah(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada data.'));
                  }

                  final listData = snapshot.data!;

                  // KUNCI PERBAIKAN: Menambahkan 'return' di depan ListView.builder
                  return ListView.builder(
                    itemCount: listData.length,
                    itemBuilder: (context, index) {
                      final item = listData[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            item.namaSampah,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            item.listHarga.isNotEmpty
                                ? 'Harga: Rp ${item.listHarga.last.hargaPerKg} / kg'
                                : 'Harga: Belum diatur',
                            style: TextStyle(
                              color: item.listHarga.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Tombol Atur Harga ($ Hijau)
                              IconButton(
                                icon: const Icon(Icons.attach_money,
                                    color: Colors.green),
                                tooltip: 'Atur Harga',
                                onPressed: () => _showAturHargaDialog(item),
                              ),
                              // 2. Tombol Edit Nama (Pensil Biru)
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(item),
                              ),
                              // 3. Tombol Hapus (Sampah Merah)
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(item.id),
                              ),
                            ],
                          ),
                        ),
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
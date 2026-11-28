import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/services/api_service.dart';
import 'package:bank_sampah_flutter/models/jenis_sampah_model.dart';
import 'package:flutter/services.dart';

class JenisSampahScreen extends StatefulWidget {
  const JenisSampahScreen({Key? key}) : super(key: key);

  @override
  State<JenisSampahScreen> createState() => _JenisSampahScreenState();
}

class _JenisSampahScreenState extends State<JenisSampahScreen> {
  final TextEditingController _tambahController = TextEditingController();
  final TextEditingController _hargaTambahController = TextEditingController();

  final _hargaInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.,]'),
  );

  double? _parseHarga(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  late Future<List<JenisSampah>> _jenisSampahFuture;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    _jenisSampahFuture = ApiService.getJenisSampah();
  }

  @override
  void dispose() {
    _tambahController.dispose();
    _hargaTambahController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (!mounted) return;

    setState(() {
      _jenisSampahFuture = ApiService.getJenisSampah();
    });
  }

  void _tampilkanPesan(String pesan, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: error ? Color(0xFFB42318) : AppColors.primary,
        ),
      );
  }

  String _pesanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // TAMBAH JENIS SAMPAH
  Future<void> _tambahJenisSampah() async {
    final nama = _tambahController.text.trim();
    final harga = _parseHarga(_hargaTambahController.text);

    if (nama.isEmpty) {
      _tampilkanPesan('Nama jenis sampah wajib diisi.', error: true);
      return;
    }

    if (harga == null || harga <= 0) {
      _tampilkanPesan('Masukkan harga per kg yang valid.', error: true);
      return;
    }

    setState(() => _sedangMenyimpan = true);

    try {
      await ApiService.tambahJenisSampah(
        namaSampah: nama,
        hargaPerGram: harga,
        status: true,
      );

      _tambahController.clear();
      _hargaTambahController.clear();

      _refreshData();
      _tampilkanPesan('Jenis sampah berhasil ditambahkan.');
    } catch (e) {
      _tampilkanPesan(_pesanError(e), error: true);
    } finally {
      if (mounted) {
        setState(() => _sedangMenyimpan = false);
      }
    }
  }

  // EDIT NAMA JENIS SAMPAH
  Future<void> _showEditDialog(JenisSampah item) async {
    final controller = TextEditingController(text: item.namaSampah);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Jenis Sampah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s()]')),
          ],
          decoration: AppStyles.inputDecoration(
            'Nama Jenis Sampah',
            icon: Icons.edit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nama = controller.text.trim();

              if (nama.isEmpty) {
                _tampilkanPesan(
                  'Nama jenis sampah tidak boleh kosong.',
                  error: true,
                );
                return;
              }

              try {
                await ApiService.updateJenisSampah(
                  id: item.idJenisSampah,
                  namaSampah: nama,
                  hargaPerGram: item.hargaPerGram,
                  status: item.status,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);
                _refreshData();
                _tampilkanPesan('Nama jenis sampah berhasil diperbarui.');
              } catch (e) {
                _tampilkanPesan(_pesanError(e), error: true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  // HAPUS JENIS SAMPAH
  Future<void> _showDeleteDialog(JenisSampah item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Jenis Sampah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah kamu yakin ingin menghapus jenis sampah ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFB42318),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      await ApiService.deleteJenisSampah(
        idJenisSampah: item.idJenisSampah,
        idHarga: item.idHarga,
      );
      _refreshData();
      _tampilkanPesan('Jenis sampah berhasil dihapus.');
    } catch (e) {
      _tampilkanPesan(_pesanError(e), error: true);
    }
  }

  // ATUR HARGA SAMPAH
  Future<void> _showAturHargaDialog(JenisSampah item) async {
    final controller = TextEditingController(
      text: item.idHarga != null ? item.hargaPerGram.toString() : '',
    );

    final adaHarga = item.idHarga != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          adaHarga ? 'Edit Harga Sampah' : 'Atur Harga Sampah',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.namaSampah,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_hargaInputFormatter],
              decoration: AppStyles.inputDecoration(
                'Harga per Kg (Rp)',
                icon: Icons.payments,
              ),
            ),
          ],
        ),
        actions: [
          if (adaHarga)
            TextButton(
              onPressed: () async {
                try {
                  await ApiService.deleteHargaSampah(item.idHarga!);

                  if (!mounted) return;

                  Navigator.pop(dialogContext);
                  _refreshData();
                  _tampilkanPesan('Harga sampah berhasil dihapus.');
                } catch (e) {
                  _tampilkanPesan(_pesanError(e), error: true);
                }
              },
              child: const Text(
                'Hapus Harga',
                style: TextStyle(color: Color(0xFFB42318)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final harga = _parseHarga(controller.text);

              if (harga == null || harga <= 0) {
                _tampilkanPesan(
                  'Masukkan harga per kg yang valid.',
                  error: true,
                );
                return;
              }

              try {
                if (adaHarga) {
                  await ApiService.updateHargaSampah(item.idHarga!, harga);
                } else {
                  await ApiService.tambahHargaSampah(item.idJenisSampah, harga);
                }

                if (!mounted) return;

                Navigator.pop(dialogContext);
                _refreshData();
                _tampilkanPesan('Harga sampah berhasil disimpan.');
              } catch (e) {
                _tampilkanPesan(_pesanError(e), error: true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();
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
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _tambahController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZÀ-ÿ\s()]'),
                      ),
                    ],
                    textCapitalization: TextCapitalization.words,
                    decoration: AppStyles.inputDecoration(
                      'Nama Jenis Sampah',
                      icon: Icons.recycling,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _hargaTambahController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_hargaInputFormatter],
                    decoration: AppStyles.inputDecoration(
                      'Harga per Kg (Rp)',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sedangMenyimpan ? null : _tambahJenisSampah,
                      icon: _sedangMenyimpan
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(
                        _sedangMenyimpan
                            ? 'Menyimpan...'
                            : 'Tambah Jenis Sampah',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daftar Jenis Sampah',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<JenisSampah>>(
                future: _jenisSampahFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFB42318),
                              size: 42,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Gagal mengambil data jenis sampah.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada data sampah.',
                        style: TextStyle(
                          color: Color(0xFF71847F),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  final listData = snapshot.data!;

                  return ListView.builder(
                    itemCount: listData.length,
                    itemBuilder: (context, index) {
                      final item = listData[index];

                      return SampahItemCard(
                        item: item,
                        onAturHarga: () => _showAturHargaDialog(item),
                        onEdit: () => _showEditDialog(item),
                        onDelete: () => _showDeleteDialog(item),
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

// WARNA
class AppColors {
  static const Color primary = Color(0xFF2D765D);
  static const Color secondary = Color(0xFFE6F5ED);
  static const Color background = Color(0xFFEDF1EF);
}

// STYLE INPUT
class AppStyles {
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

// KARTU JENIS SAMPAH
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
    final adaHarga = item.idHarga != null;

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
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            adaHarga
                ? 'Rp ${item.hargaPerGram.toStringAsFixed(0)} / kg'
                : 'Harga: Belum diatur',
            style: TextStyle(
              color: adaHarga ? Color(0xFF166534) : Color(0xFFD88916),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Aksi',
          onSelected: (value) {
            switch (value) {
              case 'harga':
                onAturHarga();
                break;
              case 'edit':
                onEdit();
                break;
              case 'hapus':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'harga',
              child: ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Atur Harga'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit Nama'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'hapus',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Color(0xFFB42318)),
                title: Text('Hapus'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

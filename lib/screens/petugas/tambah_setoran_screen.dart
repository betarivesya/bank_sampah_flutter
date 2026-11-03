import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../models/jenis_sampah_model.dart';
import '../../services/api_service.dart';

class TambahSetoranScreen extends StatefulWidget {
  final int idPetugas;

  const TambahSetoranScreen({super.key, required this.idPetugas});

  @override
  State<TambahSetoranScreen> createState() => _TambahSetoranScreenState();
}

class _TambahSetoranScreenState extends State<TambahSetoranScreen> {
  List<Map<String, dynamic>> _nasabah = [];
  List<JenisSampah> _jenisSampah = [];

  Map<String, dynamic>? _nasabahTerpilih;
  final TextEditingController _nasabahSearchController =
      TextEditingController();
  Timer? _nasabahSearchTimer;

  final List<_ItemSetoran> _items = [];

  bool _loading = true;
  bool _saving = false;

  static const Color _hijau = Color(0xFF075B4F);
  static const Color _latar = Color(0xFFF6F8F7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nasabahSearchTimer?.cancel();
    _nasabahSearchController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      final hasil = await Future.wait([
        ApiService.getPetugasNasabahPage(perPage: 20),
        ApiService.getJenisSampah(),
      ]);

      if (!mounted) return;

      setState(() {
        _nasabah = (hasil[0] as PetugasPage<Map<String, dynamic>>).items;
        _jenisSampah = hasil[1] as List<JenisSampah>;
        _loading = false;

        if (_items.isEmpty) {
          _items.add(_ItemSetoran());
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _searchNasabah(String keyword) {
    _nasabahSearchTimer?.cancel();
    _nasabahSearchTimer = Timer(const Duration(milliseconds: 350), () async {
      if (keyword.trim().isEmpty) {
        if (mounted) setState(() => _nasabah = []);
        return;
      }

      try {
        final result = await ApiService.getPetugasNasabahPage(
          keyword: keyword,
          perPage: 20,
        );
        if (!mounted) return;
        setState(() => _nasabah = result.items);
      } catch (_) {
        if (mounted) setState(() => _nasabah = []);
      }
    });
  }

  // ============================================================
  // PERHITUNGAN
  // ============================================================

  double _berat(_ItemSetoran item) {
    return double.tryParse(
          item.beratController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  double _hargaPerKg(_ItemSetoran item) {
    return item.jenisTerpilih?.hargaPerKg.toDouble() ?? 0;
  }

  double _subtotal(_ItemSetoran item) {
    return _berat(item) * _hargaPerKg(item);
  }

  double get _totalBerat {
    return _items.fold(0, (total, item) => total + _berat(item));
  }

  double get _totalNilai {
    return _items.fold(0, (total, item) => total + _subtotal(item));
  }

  // ============================================================
  // ITEM SETORAN
  // ============================================================

  void _tambahItem() {
    if (_saving) return;

    setState(() {
      _items.add(_ItemSetoran());
    });
  }

  void _hapusItem(int index) {
    if (_saving || _items.length <= 1) return;

    final item = _items.removeAt(index);
    item.dispose();

    setState(() {});
  }

  void _pilihJenis(_ItemSetoran item, JenisSampah? jenis) {
    if (_saving) return;

    setState(() {
      item.jenisTerpilih = jenis;
    });
  }

  // ============================================================
  // VALIDASI DAN SIMPAN
  // ============================================================

  Future<void> _simpan() async {
    if (_saving) return;

    if (_nasabahTerpilih == null) {
      _showError('Silakan pilih nasabah.');
      return;
    }

    if (_items.isEmpty) {
      _showError('Tambahkan minimal satu jenis sampah.');
      return;
    }

    final idsJenis = <int>{};

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      if (item.jenisTerpilih == null) {
        _showError('Pilih jenis sampah pada baris ${i + 1}.');
        return;
      }

      if (!idsJenis.add(item.jenisTerpilih!.idJenisSampah)) {
        _showError(
          'Jenis sampah tidak boleh dipilih lebih dari sekali. '
          'Periksa baris ${i + 1}.',
        );
        return;
      }

      if (_berat(item) <= 0) {
        _showError('Berat sampah pada baris ${i + 1} harus lebih dari 0 kg.');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final itemsRequest = _items.map((item) {
        return <String, dynamic>{
          'id_jenis_sampah': item.jenisTerpilih!.idJenisSampah,
          'total_berat': _berat(item),
        };
      }).toList();

      await ApiService.tambahSetoran(
        idNasabah: int.parse(
          _nasabahTerpilih!['id_pengguna_nasabah']?.toString() ??
              _nasabahTerpilih!['id_nasabah'].toString(),
        ),
        idPetugas: widget.idPetugas,
        items: itemsRequest,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setoran berhasil disimpan.'),
          backgroundColor: _hijau,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _latar,
      appBar: AppBar(
        backgroundColor: _hijau,
        foregroundColor: Colors.white,
        title: const Text('Tambah Setoran'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _hijau))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildNasabahSection(),
                const SizedBox(height: 18),
                _buildItemsSection(),
                const SizedBox(height: 18),
                _buildTotalCard(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _simpan,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Menyimpan...' : 'Simpan Setoran',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hijau,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ============================================================
  // NASABAH
  // ============================================================

  Widget _buildNasabahSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(number: '1', title: 'Pilih Nasabah'),
          const SizedBox(height: 14),
          TextField(
            controller: _nasabahSearchController,
            enabled: !_saving,
            onChanged: (value) {
              setState(() {
                _nasabahTerpilih = null;
              });
              _searchNasabah(value);
            },
            decoration:
                _inputDecoration(
                  'Cari nama, nomor HP, atau email nasabah',
                  Icons.search,
                ).copyWith(
                  suffixIcon: _nasabahSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _nasabahSearchController.clear();
                            setState(() {
                              _nasabah = [];
                              _nasabahTerpilih = null;
                            });
                          },
                        ),
                ),
          ),
          if (_nasabahTerpilih != null) ...[
            const SizedBox(height: 8),
            Text(
              'Nasabah dipilih: ${_namaNasabah(_nasabahTerpilih!)}',
              style: const TextStyle(
                color: _hijau,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (_nasabahSearchController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._nasabah.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline, color: _hijau),
                title: Text(_namaNasabah(item)),
                subtitle: Text(
                  item['no_hp']?.toString() ??
                      item['no_telp']?.toString() ??
                      item['email']?.toString() ??
                      '-',
                ),
                onTap: () {
                  setState(() {
                    _nasabahTerpilih = item;
                    _nasabah = [];
                    _nasabahSearchController.text = _namaNasabah(item);
                  });
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _namaNasabah(Map<String, dynamic> item) {
    return item['nama']?.toString() ??
        item['nama_lengkap']?.toString() ??
        'Nasabah';
  }

  // ============================================================
  // DAFTAR JENIS SAMPAH
  // ============================================================

  Widget _buildItemsSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(number: '2', title: 'Detail Sampah'),
              ),
              Text(
                '${_items.length} item',
                style: const TextStyle(
                  color: _hijau,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih jenis sampah dan masukkan berat setiap item.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 14),

          ...List.generate(_items.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildItemCard(index),
            );
          }),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _tambahItem,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambah Jenis Sampah'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _hijau,
                side: const BorderSide(color: _hijau),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    // Jenis sampah yang dipilih pada baris lain tidak ditampilkan
    // sebagai pilihan agar tidak terjadi duplikasi.
    final jenisTersedia = _jenisSampah.where((jenis) {
      return jenis.idJenisSampah == item.jenisTerpilih?.idJenisSampah ||
          !_items.any(
            (lain) =>
                !identical(lain, item) &&
                lain.jenisTerpilih?.idJenisSampah == jenis.idJenisSampah,
          );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        border: Border.all(color: const Color(0xFFE0E8E4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF1E9),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _hijau,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Jenis Sampah',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Hapus item',
                onPressed: _saving || _items.length <= 1
                    ? null
                    : () => _hapusItem(index),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<JenisSampah>(
            value: item.jenisTerpilih,
            isExpanded: true,
            decoration: _inputDecoration('Pilih jenis sampah', Icons.recycling),
            items: jenisTersedia.map((jenis) {
              return DropdownMenuItem<JenisSampah>(
                value: jenis,
                child: Text(jenis.namaSampah, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: _saving ? null : (value) => _pilihJenis(item, value),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: item.beratController,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(
              'Masukkan berat',
              Icons.scale_outlined,
            ).copyWith(hintText: 'Contoh: 2.5', suffixText: 'kg'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Harga/kg', style: TextStyle(color: Colors.black54)),
              Text(
                rupiah(_hargaPerKg(item)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                rupiah(_subtotal(item)),
                style: const TextStyle(
                  color: _hijau,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOTAL TRANSAKSI
  // ============================================================

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDE8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: _hijau),
              SizedBox(width: 8),
              Text(
                'Ringkasan Setoran',
                style: TextStyle(
                  color: _hijau,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Jumlah jenis sampah', '${_items.length} item'),
          const SizedBox(height: 10),
          _summaryRow('Total berat', '${_totalBerat.toStringAsFixed(2)} kg'),
          const Divider(height: 24),
          const Text('Total Nilai Setoran', style: TextStyle(color: _hijau)),
          const SizedBox(height: 5),
          Text(
            rupiah(_totalNilai),
            style: const TextStyle(
              color: _hijau,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _hijau),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E8E4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E8E4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _hijau, width: 1.5),
      ),
    );
  }
}

// ============================================================
// MODEL ITEM FORM
// ============================================================

class _ItemSetoran {
  JenisSampah? jenisTerpilih;
  final TextEditingController beratController = TextEditingController();

  void dispose() {
    beratController.dispose();
  }
}

// ============================================================
// WIDGET KARTU
// ============================================================

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String number;
  final String title;

  const _SectionTitle({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF075B4F),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

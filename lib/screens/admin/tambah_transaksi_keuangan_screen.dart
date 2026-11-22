import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class TambahTransaksiKeuanganScreen extends StatefulWidget {
  const TambahTransaksiKeuanganScreen({
    super.key,
    required this.jenisSampah,
    required this.saldoAwalSudahAda,
  });

  final List<Map<String, dynamic>> jenisSampah;
  final bool saldoAwalSudahAda;

  @override
  State<TambahTransaksiKeuanganScreen> createState() =>
      _TambahTransaksiKeuanganScreenState();
}

class _TambahTransaksiKeuanganScreenState
    extends State<TambahTransaksiKeuanganScreen> {
  static const Color darkGreen = Color(0xFF0F463D);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  final List<_SaleLine> _saleLines = [_SaleLine()];

  String _jenisTransaksi = 'pemasukan';
  late String _kategori;
  DateTime _tanggalTransaksi = DateTime.now();
  PlatformFile? _buktiTransaksi;
  Uint8List? _buktiBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _kategori = widget.saldoAwalSudahAda ? 'tambahan_modal' : 'saldo_awal';
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    for (final line in _saleLines) {
      line.dispose();
    }
    super.dispose();
  }

  bool get _isPenjualan => _kategori == 'penjualan_induk';

  bool get _buktiWajib =>
      _kategori == 'penjualan_induk' || _kategori == 'operasional';

  Future<void> _pickProof() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (file == null || !mounted) return;

      final size = file.lengthSync() ?? await file.length();
      if (!mounted) return;

      if (size == null) {
        _showMessage('Ukuran file bukti tidak dapat dibaca.');
        return;
      }

      if (size > 5 * 1024 * 1024) {
        _showMessage('Ukuran bukti transaksi maksimal 5 MB.');
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _buktiTransaksi = file;
        _buktiBytes = bytes;
      });
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Gagal memilih bukti transaksi: '
          '${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tanggalTransaksi,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      setState(() {
        _tanggalTransaksi = date;
      });
    }
  }

  String _dateValue(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _onCategoryChanged(String? value) {
    if (value == null) return;

    setState(() {
      _kategori = value;
      if (value == 'operasional') {
        _jenisTransaksi = 'pengeluaran';
      } else if (value != 'lainnya') {
        _jenisTransaksi = 'pemasukan';
      }
    });
  }

  void _onTransactionTypeChanged(String? value) {
    if (value == null) return;

    setState(() {
      _jenisTransaksi = value;
      if (value == 'pengeluaran' &&
          _kategori != 'operasional' &&
          _kategori != 'lainnya') {
        _kategori = 'lainnya';
      } else if (value == 'pemasukan' && _kategori == 'operasional') {
        _kategori = 'lainnya';
      }
    });
  }

  void _addSaleLine() {
    setState(() {
      _saleLines.add(_SaleLine());
    });
  }

  void _removeSaleLine(_SaleLine line) {
    if (_saleLines.length == 1) return;

    setState(() {
      _saleLines.remove(line);
      line.dispose();
    });
  }

  double get _saleTotal {
    return _saleLines.fold<double>(0, (total, line) {
      final weight = double.tryParse(line.beratController.text) ?? 0;
      final pricePerGram = double.tryParse(line.hargaController.text) ?? 0;
      return total + (weight * pricePerGram * 1000);
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPenjualan && widget.jenisSampah.isEmpty) {
      _showMessage('Belum ada jenis sampah aktif yang dapat dipilih.');
      return;
    }

    if (_buktiWajib && _buktiTransaksi == null) {
      _showMessage('Bukti transaksi wajib diunggah untuk kategori ini.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final details = _isPenjualan
          ? _saleLines
                .map(
                  (line) => <String, dynamic>{
                    'id_jenis_sampah': line.idJenisSampah,
                    'berat_kg': line.beratController.text.trim(),
                    'harga_per_kg': line.hargaController.text.trim(),
                  },
                )
                .toList()
          : <Map<String, dynamic>>[];

      await ApiService.storeAdminKeuangan(
        jenisTransaksi: _jenisTransaksi,
        kategori: _kategori,
        tanggalTransaksi: _dateValue(_tanggalTransaksi),
        keterangan: _keteranganController.text,
        nominal: _isPenjualan ? null : _nominalController.text,
        detailPenjualan: details,
        buktiBytes: _buktiBytes,
        buktiNamaFile: _buktiTransaksi?.name,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validatePositiveNumber(String? value, String label) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) {
      return '$label harus lebih dari 0.';
    }

    return null;
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'saldo_awal' => 'Saldo awal kas',
      'tambahan_modal' => 'Tambahan modal',
      'penjualan_induk' => 'Penjualan ke bank sampah induk',
      'operasional' => 'Pengeluaran operasional',
      _ => 'Lainnya',
    };
  }

  Widget _buildSaleLine(_SaleLine line) {
    final selectedId = int.tryParse(line.idJenisSampah ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Jenis sampah',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_saleLines.length > 1)
                  IconButton(
                    tooltip: 'Hapus jenis sampah',
                    onPressed: _isSaving ? null : () => _removeSaleLine(line),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
              ],
            ),
            DropdownButtonFormField<int>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.jenisSampah.map((jenis) {
                final id = int.tryParse(
                  jenis['id_jenis_sampah']?.toString() ?? '',
                );

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(jenis['nama_sampah']?.toString() ?? '-'),
                );
              }).toList(),
              validator: (value) =>
                  value == null ? 'Pilih jenis sampah.' : null,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      line.idJenisSampah = value?.toString();
                    },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: line.beratController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Berat (kg)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) => _validatePositiveNumber(value, 'Berat'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: line.hargaController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Harga per gram (Rp)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) =>
                  _validatePositiveNumber(value, 'Harga per gram'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>[
      if (!widget.saldoAwalSudahAda) 'saldo_awal',
      'tambahan_modal',
      'penjualan_induk',
      'operasional',
      'lainnya',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Catat transaksi'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(_jenisTransaksi),
              initialValue: _jenisTransaksi,
              decoration: const InputDecoration(
                labelText: 'Jenis transaksi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pemasukan', child: Text('Pemasukan')),
                DropdownMenuItem(
                  value: 'pengeluaran',
                  child: Text('Pengeluaran'),
                ),
              ],
              onChanged: _isSaving ? null : _onTransactionTypeChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_kategori),
              initialValue: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(_categoryLabel(category)),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving ? null : _onCategoryChanged,
            ),
            if (widget.saldoAwalSudahAda) ...[
              const SizedBox(height: 6),
              const Text(
                'Saldo awal sudah tercatat. Gunakan Tambahan Modal untuk dana berikutnya.',
                style: TextStyle(color: Color(0xFF71847F), fontSize: 12),
              ),
            ],
            if (!_isPenjualan) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _nominalController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validatePositiveNumber(value, 'Nominal'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text('Tanggal: ${_dateValue(_tanggalTransaksi)}'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _keteranganController,
              enabled: !_isSaving,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_isPenjualan) ...[
              const SizedBox(height: 12),
              const Text(
                'Detail penjualan ke induk',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.jenisSampah.isEmpty)
                const Text(
                  'Belum ada jenis sampah aktif yang dapat dipilih.',
                  style: TextStyle(color: Color(0xFFB91C1C)),
                )
              else
                ..._saleLines.map(_buildSaleLine),
              OutlinedButton.icon(
                onPressed: _isSaving || widget.jenisSampah.isEmpty
                    ? null
                    : _addSaleLine,
                icon: const Icon(Icons.add),
                label: const Text('Tambah jenis sampah'),
              ),
              const SizedBox(height: 8),
              Text(
                'Perkiraan total: Rp${_saleTotal.round()}',
                style: const TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Total final dihitung kembali oleh server berdasarkan berat dan harga per gram.',
                style: TextStyle(color: Color(0xFF71847F), fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickProof,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _buktiTransaksi?.name ?? 'Pilih bukti transaksi (JPG/PNG/PDF)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _buktiWajib
                  ? 'Wajib untuk penjualan ke induk dan pengeluaran operasional. Maksimal 5 MB.'
                  : 'Opsional. Format JPG, PNG, atau PDF; maksimal 5 MB.',
              style: const TextStyle(color: Color(0xFF71847F), fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveTransaction,
              style: FilledButton.styleFrom(
                backgroundColor: darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleLine {
  String? idJenisSampah;
  final TextEditingController beratController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();

  void dispose() {
    beratController.dispose();
    hargaController.dispose();
  }
}

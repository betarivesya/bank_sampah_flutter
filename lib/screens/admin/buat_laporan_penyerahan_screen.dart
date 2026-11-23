import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class BuatLaporanPenyerahanScreen extends StatefulWidget {
  const BuatLaporanPenyerahanScreen({super.key});

  @override
  State<BuatLaporanPenyerahanScreen> createState() =>
      _BuatLaporanPenyerahanScreenState();
}

class _BuatLaporanPenyerahanScreenState
    extends State<BuatLaporanPenyerahanScreen> {
  static const Color green = Color(0xFF123D36);

  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _items = [];
  DateTime _tanggal = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    try {
      final data = await ApiService.getDataBuatLaporanPenyerahan();

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(
            data.map((item) {
              final berat = _angka(item['berat_otomatis']);
              return {
                'id_jenis_sampah': item['id_jenis_sampah'],
                'nama_sampah': item['nama_sampah'] ?? '-',
                'berat_otomatis': berat,
                'berat_kg': berat,
                'harga_per_kg': 0.0,
                'beratController': TextEditingController(
                  text: berat.toStringAsFixed(3),
                ),
                'hargaController': TextEditingController(text: '0'),
              };
            }),
          );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatTanggalApi(DateTime tanggal) {
    final tahun = tanggal.year.toString().padLeft(4, '0');
    final bulan = tanggal.month.toString().padLeft(2, '0');
    final hari = tanggal.day.toString().padLeft(2, '0');

    return '$tahun-$bulan-$hari';
  }

  double _angka(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _subtotal(Map<String, dynamic> item) {
    return _angka(item['berat_kg']) * _angka(item['harga_per_kg']);
  }

  double get _totalBerat =>
      _items.fold(0, (total, item) => total + _angka(item['berat_kg']));

  double get _totalNominal =>
      _items.fold(0, (total, item) => total + _subtotal(item));

  String _rupiah(double value) {
    final angka = value.round().toString();
    return 'Rp ${angka.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  Future<void> _pilihTanggal() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() => _tanggal = result);
    }
  }

  Future<void> _simpanDraft() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada jenis sampah aktif.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final items = _items.map((item) {
        return {
          'id_jenis_sampah': item['id_jenis_sampah'],
          'berat_kg': _angka(item['berat_kg']),
          'harga_per_kg': _angka(item['harga_per_kg']),
        };
      }).toList();

      final tanggal =
          '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-'
          '${_tanggal.day.toString().padLeft(2, '0')}';

      await ApiService.simpanDraftLaporanPenyerahan(
        tanggalLaporan: tanggal,
        items: items,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft laporan berhasil disimpan.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      (item['beratController'] as TextEditingController).dispose();
      (item['hargaController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        title: const Text('Buat Laporan Penyerahan'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Informasi Laporan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pilihTanggal,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: green),
                          const SizedBox(width: 10),
                          Text(
                            'Tanggal: ${_tanggal.day.toString().padLeft(2, '0')}/'
                            '${_tanggal.month.toString().padLeft(2, '0')}/'
                            '${_tanggal.year}',
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Rincian Stok Sampah',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nama_sampah'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Berat otomatis: '
                            '${_angka(item['berat_otomatis']).toStringAsFixed(3)} Kg',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller:
                                item['beratController']
                                    as TextEditingController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Berat Final (Kg)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final number = double.tryParse(
                                (value ?? '').replaceAll(',', '.'),
                              );
                              if (number == null || number < 0) {
                                return 'Masukkan berat yang valid';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final number = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              setState(() {
                                item['berat_kg'] = number ?? 0;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller:
                                item['hargaController']
                                    as TextEditingController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Harga per Kg (Rp)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final number = double.tryParse(
                                (value ?? '').replaceAll(',', '.'),
                              );
                              if (number == null || number < 0) {
                                return 'Masukkan harga yang valid';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final number = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              setState(() {
                                item['harga_per_kg'] = number ?? 0;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Subtotal: ${_rupiah(_subtotal(item))}',
                              style: const TextStyle(
                                color: green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      children: [
                        _totalRow(
                          'Total Berat',
                          '${_totalBerat.toStringAsFixed(3)} Kg',
                        ),
                        const Divider(),
                        _totalRow('Total Nominal', _rupiah(_totalNominal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _simpanDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan Draft'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

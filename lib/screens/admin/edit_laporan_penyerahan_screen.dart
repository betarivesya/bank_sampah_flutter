import 'package:flutter/material.dart';

import '../../models/laporan_penyerahan_induk_model.dart';
import '../../services/api_service.dart';

class EditLaporanPenyerahanScreen extends StatefulWidget {
  final int idLaporan;

  const EditLaporanPenyerahanScreen({super.key, required this.idLaporan});

  @override
  State<EditLaporanPenyerahanScreen> createState() =>
      _EditLaporanPenyerahanScreenState();
}

class _EditLaporanPenyerahanScreenState
    extends State<EditLaporanPenyerahanScreen> {
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

  double _angka(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          value?.toString().trim().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  Future<void> _muatData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final laporan = await ApiService.getDetailLaporanPenyerahan(
        widget.idLaporan,
      );

      if (!mounted) return;

      // Halaman edit hanya digunakan untuk laporan berstatus draft.
      if (laporan.status != 'draft') {
        setState(() {
          _error = 'Hanya laporan berstatus Draft yang dapat diedit.';
          _loading = false;
        });
        return;
      }

      // Bersihkan controller lama jika data dimuat ulang.
      _bersihkanController();

      final bagianTanggal = laporan.tanggalLaporan.length >= 10
          ? laporan.tanggalLaporan.substring(0, 10).split('-')
          : <String>[];

      DateTime? tanggal;

      if (bagianTanggal.length == 3) {
        tanggal = DateTime(
          int.parse(bagianTanggal[0]),
          int.parse(bagianTanggal[1]),
          int.parse(bagianTanggal[2]),
        );
      }

      setState(() {
        if (tanggal != null) {
          _tanggal = tanggal;
        }

        _items
          ..clear()
          ..addAll(
            laporan.detailLaporan.map((item) {
              return {
                'id_jenis_sampah': item.idJenisSampah,
                'nama_sampah': item.namaSampah,
                'berat_otomatis': item.beratOtomatis,
                'berat_kg': item.beratFinal,
                'harga_per_kg': item.hargaPerKg,
                'beratController': TextEditingController(
                  text: item.beratFinal.toStringAsFixed(3),
                ),
                'hargaController': TextEditingController(
                  text: item.hargaPerKg.toStringAsFixed(0),
                ),
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

  void _bersihkanController() {
    for (final item in _items) {
      (item['beratController'] as TextEditingController).dispose();
      (item['hargaController'] as TextEditingController).dispose();
    }
    _items.clear();
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

    if (result != null && mounted) {
      setState(() => _tanggal = result);
    }
  }

  Future<void> _simpanPerubahan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada rincian laporan.')),
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

      await ApiService.updateDraftLaporanPenyerahan(
        idLaporan: widget.idLaporan,
        tanggalLaporan: tanggal,
        items: items,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan penyerahan berhasil diperbarui.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui laporan: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _bersihkanController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        title: const Text('Edit Laporan Penyerahan'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _muatData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
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
                            'Tanggal: '
                            '${_tanggal.day.toString().padLeft(2, '0')}/'
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
                      onPressed: _saving ? null : _simpanPerubahan,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                      ),
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

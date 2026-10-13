import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../models/jenis_sampah_model.dart';
import '../../services/api_service.dart';

class TambahSetoranScreen extends StatefulWidget {
  const TambahSetoranScreen({super.key});

  @override
  State<TambahSetoranScreen> createState() => _TambahSetoranScreenState();
}

class _TambahSetoranScreenState extends State<TambahSetoranScreen> {
  List<Map<String, dynamic>> _nasabah = [];
  List<JenisSampah> _jenisSampah = [];

  Map<String, dynamic>? _nasabahTerpilih;
  JenisSampah? _jenisTerpilih;

  final TextEditingController _beratController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  // ============================================================
  // ID PETUGAS
  // ============================================================

  final int _idPetugas = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _beratController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      final nasabah = await ApiService.getNasabah();
      final jenisSampah = await ApiService.getJenisSampah();

      if (!mounted) return;

      setState(() {
        _nasabah = nasabah;
        _jenisSampah = jenisSampah;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // HITUNG TOTAL
  // ============================================================

  double get _berat {
    return double.tryParse(_beratController.text.replaceAll(',', '.')) ?? 0;
  }

  double get _hargaPerKg {
    if (_jenisTerpilih == null) return 0;

    return _jenisTerpilih!.hargaPerKg;
  }

  double get _total {
    return _berat * _hargaPerKg;
  }

  // ============================================================
  // SIMPAN
  // ============================================================

  Future<void> _simpan() async {
    if (_nasabahTerpilih == null) {
      _showError('Silakan pilih nasabah.');
      return;
    }

    if (_jenisTerpilih == null) {
      _showError('Silakan pilih jenis sampah.');
      return;
    }

    if (_berat <= 0) {
      _showError('Berat sampah harus lebih dari 0 kg.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ApiService.tambahSetoran(
        idNasabah: int.parse(_nasabahTerpilih!['id_nasabah'].toString()),
        idPetugas: _idPetugas,
        idJenisSampah: _jenisTerpilih!.idJenisSampah,
        totalBerat: _berat,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setoran berhasil disimpan.'),
          backgroundColor: Color(0xFF075B4F),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

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
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075B4F),
        foregroundColor: Colors.white,
        title: const Text('Tambah Setoran'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF075B4F)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionTitle(number: '1', title: 'Pilih Nasabah'),
                const SizedBox(height: 10),

                _buildNasabahDropdown(),

                const SizedBox(height: 24),

                _SectionTitle(number: '2', title: 'Pilih Jenis Sampah'),
                const SizedBox(height: 10),

                _buildJenisSampahDropdown(),

                const SizedBox(height: 24),

                _SectionTitle(number: '3', title: 'Masukkan Berat Sampah'),
                const SizedBox(height: 10),

                TextField(
                  controller: _beratController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Contoh: 2.5',
                    suffixText: 'kg',
                    prefixIcon: const Icon(Icons.scale),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _buildTotalCard(),

                const SizedBox(height: 30),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075B4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Setoran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  // ============================================================
  // NASABAH
  // ============================================================

  Widget _buildNasabahDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _nasabahTerpilih,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF075B4F)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: const Text('Pilih nasabah'),
      items: _nasabah.map((item) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: item,
          child: Text(item['nama']?.toString() ?? '-'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _nasabahTerpilih = value;
        });
      },
    );
  }

  // ============================================================
  // JENIS SAMPAH
  // ============================================================

  Widget _buildJenisSampahDropdown() {
    return DropdownButtonFormField<JenisSampah>(
      value: _jenisTerpilih,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.recycling, color: Color(0xFF075B4F)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: const Text('Pilih jenis sampah'),
      items: _jenisSampah.map((item) {
        return DropdownMenuItem<JenisSampah>(
          value: item,
          child: Text(item.namaSampah),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _jenisTerpilih = value;
        });
      },
    );
  }

  // ============================================================
  // TOTAL
  // ============================================================

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Nilai Setoran',
            style: TextStyle(
              color: Color(0xFF075B4F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rupiah(_total),
            style: const TextStyle(
              color: Color(0xFF075B4F),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Berat'),
              Text(
                '${_berat.toStringAsFixed(2)} kg',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Harga/kg'),
              Text(
                rupiah(_hargaPerKg),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

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
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

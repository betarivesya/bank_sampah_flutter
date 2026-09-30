import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/app_styles.dart';
import 'package:bank_sampah_flutter/data/petugas_dummy_data.dart';
import 'package:bank_sampah_flutter/models/petugas_model.dart';

class TambahSetoranScreen extends StatefulWidget {
  const TambahSetoranScreen({super.key});

  @override
  State<TambahSetoranScreen> createState() => _TambahSetoranScreenState();
}

class _TambahSetoranScreenState extends State<TambahSetoranScreen> {
  DummyNasabah? _nasabahTerpilih;
  DummyJenisSampah? _jenisTerpilih;
  final TextEditingController _beratController = TextEditingController();

  double get _berat {
    return double.tryParse(_beratController.text.replaceAll(',', '.')) ?? 0;
  }

  double get _total {
    if (_jenisTerpilih == null || _berat <= 0) {
      return 0;
    }

    return _berat * _jenisTerpilih!.hargaPerKg;
  }

  @override
  void initState() {
    super.initState();
    _beratController.addListener(_refreshTotal);
  }

  void _refreshTotal() => setState(() {});

  @override
  void dispose() {
    _beratController
      ..removeListener(_refreshTotal)
      ..dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_nasabahTerpilih == null) {
      _showError('Pilih nasabah terlebih dahulu.');
      return;
    }

    if (_jenisTerpilih == null) {
      _showError('Pilih jenis sampah terlebih dahulu.');
      return;
    }

    if (_berat <= 0) {
      _showError('Berat sampah harus lebih dari 0 Kg.');
      return;
    }

    if (_total <= 0) {
      _showError('Total setoran tidak valid.');
      return;
    }

    final nasabah = _nasabahTerpilih!;
    final jenis = _jenisTerpilih!;

    PetugasDummyData.setoran.add(
      DummySetoran(
        idSetoran: PetugasDummyData.nextSetoranId,
        idNasabah: nasabah.idNasabah,
        idJenisSampah: jenis.idJenisSampah,
        namaNasabah: nasabah.nama,
        namaSampah: jenis.namaSampah,
        beratKg: _berat,
        hargaPerKg: jenis.hargaPerKg,
        total: _total,
        tanggal: DateTime.now(),
      ),
    );

    // Dummy: saldo nasabah langsung bertambah.
    nasabah.saldo += _total;

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Setoran Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(
            title: '1. Pilih Nasabah',
            subtitle: 'Pastikan data nasabah sesuai dengan yang datang.',
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<DummyNasabah>(
            value: _nasabahTerpilih,
            decoration: AppDecorations.inputDecoration(
              'Nasabah',
              icon: Icons.person_outline,
            ),
            items: PetugasDummyData.nasabah
                .map(
                  (item) => DropdownMenuItem<DummyNasabah>(
                    value: item,
                    child: Text(item.nama),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _nasabahTerpilih = value;
              });
            },
          ),
          if (_nasabahTerpilih != null) ...[
            const SizedBox(height: 10),
            _SelectedNasabahCard(nasabah: _nasabahTerpilih!),
          ],
          const SizedBox(height: 24),
          const _SectionTitle(
            title: '2. Pilih Jenis Sampah',
            subtitle: 'Harga mengikuti data harga yang tersedia.',
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<DummyJenisSampah>(
            value: _jenisTerpilih,
            decoration: AppDecorations.inputDecoration(
              'Jenis Sampah',
              icon: Icons.recycling_outlined,
            ),
            items: PetugasDummyData.jenisSampah
                .map(
                  (item) => DropdownMenuItem<DummyJenisSampah>(
                    value: item,
                    child: Text(item.namaSampah),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _jenisTerpilih = value;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_jenisTerpilih != null)
            _PriceCard(harga: _jenisTerpilih!.hargaPerKg),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: '3. Timbang Sampah',
            subtitle: 'Masukkan berat dalam satuan kilogram.',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _beratController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: AppDecorations.inputDecoration(
              'Berat Sampah (Kg)',
              icon: Icons.scale_outlined,
            ),
          ),
          const SizedBox(height: 24),
          _TotalCard(total: _total),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text(
                'Simpan Setoran',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.subtitle),
      ],
    );
  }
}

class _SelectedNasabahCard extends StatelessWidget {
  final DummyNasabah nasabah;

  const _SelectedNasabahCard({required this.nasabah});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nasabah.nama,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(nasabah.noHp, style: AppTextStyles.subtitle),
                const SizedBox(height: 3),
                Text(
                  'Saldo saat ini: ${rupiah(nasabah.saldo)}',
                  style: AppTextStyles.price,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double harga;

  const _PriceCard({required this.harga});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_outlined, color: Colors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Harga per Kg',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            rupiah(harga),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;

  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Nilai Setoran',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            rupiah(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Total dihitung otomatis dari harga/kg × berat.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

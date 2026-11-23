import 'package:flutter/material.dart';

import '../../models/laporan_penyerahan_induk_model.dart';
import '../../services/api_service.dart';
import 'buat_laporan_penyerahan_screen.dart';
import 'detail_laporan_penyerahan_screen.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  static const Color green = Color(0xFF123D36);
  static const Color background = Color(0xFFF4F8F6);

  List<LaporanPenyerahanIndukModel> _laporan = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatLaporan();
  }

  Future<void> _muatLaporan() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getLaporanPenyerahanInduk();

      if (!mounted) return;
      setState(() {
        _laporan = data;
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

  int _jumlahStatus(String status) {
    return _laporan.where((item) => item.status.toLowerCase() == status).length;
  }

  String _tanggal(String value) {
    if (value.length < 10) return value;

    final tanggal = value.substring(0, 10).split('-');

    if (tanggal.length != 3) return value;

    return '${tanggal[2]}/${tanggal[1]}/${tanggal[0]}';
  }

  String _labelStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'siap_diserahkan':
        return 'Siap Diserahkan';
      case 'sudah_diserahkan':
        return 'Sudah Diserahkan';
      default:
        return status;
    }
  }

  Color _warnaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return const Color(0xFFFFF1D6);
      case 'siap_diserahkan':
        return const Color(0xFFE1EEFF);
      case 'sudah_diserahkan':
        return const Color(0xFFE0F4E9);
      default:
        return Colors.grey.shade200;
    }
  }

  Future<void> _bukaBuatLaporan() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BuatLaporanPenyerahanScreen()),
    );

    if (berhasil == true && mounted) {
      await _muatLaporan();
    }
  }

  Future<void> _bukaDetail(int id) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailLaporanPenyerahanScreen(idLaporan: id),
      ),
    );

    if (berubah == true && mounted) {
      await _muatLaporan();
    }
  }

  Widget _ringkasan(String judul, int jumlah) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              judul,
              style: const TextStyle(fontSize: 11, color: Color(0xFF71847F)),
            ),
            const SizedBox(height: 7),
            Text(
              '$jumlah',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuLaporan(LaporanPenyerahanIndukModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Laporan #${item.idLaporan}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: green,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _warnaStatus(item.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labelStatus(item.status),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF71847F),
              ),
              const SizedBox(width: 6),
              Text(
                _tanggal(item.tanggalLaporan),
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${item.jumlahJenisSampah} jenis sampah',
                style: const TextStyle(fontSize: 12, color: Color(0xFF71847F)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _bukaDetail(item.idLaporan),
              icon: const Icon(Icons.visibility_outlined, size: 17),
              label: const Text('Detail'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _isiHalaman() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFF71847F),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat laporan',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _muatLaporan,
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: green,
      onRefresh: _muatLaporan,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          const Text(
            'Laporan Penyerahan ke Bank Sampah Induk',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pendataan stok sampah yang akan diserahkan ke Bank Sampah Induk.',
            style: TextStyle(fontSize: 12, color: Color(0xFF71847F)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ringkasan('Total Laporan', _laporan.length),
              const SizedBox(width: 8),
              _ringkasan('Draft', _jumlahStatus('draft')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ringkasan('Siap Diserahkan', _jumlahStatus('siap_diserahkan')),
              const SizedBox(width: 8),
              _ringkasan('Sudah Diserahkan', _jumlahStatus('sudah_diserahkan')),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Daftar Laporan Penyerahan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 10),
          if (_laporan.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 35),
              child: Center(child: Text('Belum ada laporan penyerahan.')),
            )
          else
            ..._laporan.map(_kartuLaporan),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: _isiHalaman(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _bukaBuatLaporan,
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Laporan'),
      ),
    );
  }
}

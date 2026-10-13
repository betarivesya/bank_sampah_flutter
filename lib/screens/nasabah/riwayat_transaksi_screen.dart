import '../../app_styles.dart';

import 'package:flutter/material.dart';

import '../../models/setoran_model.dart';
import '../../services/api_service.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  final int idNasabah;

  const RiwayatTransaksiScreen({super.key, required this.idNasabah});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  bool _loading = true;
  String? _error;
  String _filter = 'Semua';

  List<SetoranModel> _setoran = [];
  List<Map<String, dynamic>> _penarikan = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final hasil = await Future.wait([
        ApiService.getSetoran(),
        ApiService.getRiwayatPenarikanNasabah(widget.idNasabah),
      ]);

      final semuaSetoran = hasil[0] as List<SetoranModel>;

      // Hanya tampilkan setoran milik nasabah yang sedang login.
      final setoranNasabah = semuaSetoran
          .where((item) => item.idNasabah == widget.idNasabah)
          .toList();

      final riwayatPenarikan = hasil[1] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        _setoran = setoranNasabah;
        _penarikan = riwayatPenarikan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  double _nominalPenarikan(Map<String, dynamic> item) {
    return double.tryParse(item['nominal'].toString()) ?? 0;
  }

  String _statusPenarikan(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString().toLowerCase();

    if (status == 'disetujui' || status == 'approved') {
      return 'Disetujui';
    }

    if (status == 'ditolak' || status == 'rejected') {
      return 'Ditolak';
    }

    return 'Menunggu';
  }

  bool _penarikanBerhasil(Map<String, dynamic> item) {
    return _statusPenarikan(item) == 'Disetujui';
  }

  List<Map<String, dynamic>> get _semuaTransaksi {
    final List<Map<String, dynamic>> hasil = [];

    for (final item in _setoran) {
      hasil.add({
        'jenis': 'Setoran',
        'judul': item.namaSampah,
        'tanggal': item.tanggal,
        'nominal': item.totalNilai,
        'status': item.status,
        'keterangan':
            '${item.totalBerat.toStringAsFixed(2)} kg • ${item.namaPetugas}',
        'urutan': _tanggal(item.tanggal),
      });
    }

    for (final item in _penarikan) {
      hasil.add({
        'jenis': 'Penarikan',
        'judul': 'Penarikan saldo',
        'tanggal': item['tgl_pengajuan']?.toString() ?? '',
        'nominal': _nominalPenarikan(item),
        'status': _statusPenarikan(item),
        'keterangan':
            item['kode_penarikan']?.toString() ?? 'Pengajuan penarikan',
        'urutan': _tanggal(item['tgl_pengajuan']?.toString() ?? ''),
      });
    }

    hasil.sort((a, b) {
      final tanggalA = a['urutan'] as DateTime?;
      final tanggalB = b['urutan'] as DateTime?;

      if (tanggalA == null && tanggalB == null) return 0;
      if (tanggalA == null) return 1;
      if (tanggalB == null) return -1;

      return tanggalB.compareTo(tanggalA);
    });

    return hasil;
  }

  List<Map<String, dynamic>> get _transaksiTerfilter {
    if (_filter == 'Semua') return _semuaTransaksi;

    return _semuaTransaksi.where((item) => item['jenis'] == _filter).toList();
  }

  double get _totalSetoran {
    return _setoran.fold<double>(0, (total, item) => total + item.totalNilai);
  }

  double get _totalPenarikanDisetujui {
    return _penarikan
        .where(_penarikanBerhasil)
        .fold<double>(0, (total, item) => total + _nominalPenarikan(item));
  }

  DateTime? _tanggal(String value) {
    if (value.isEmpty) return null;

    return DateTime.tryParse(value);
  }

  String _formatTanggal(String value) {
    final date = _tanggal(value);
    if (date == null) return value.isEmpty ? '-' : value;

    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  String _rupiah(num nominal) {
    final angka = nominal.round().toString();
    final hasil = angka.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp$hasil';
  }

  Color _warnaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
      case 'selesai':
      case 'berhasil':
      case 'active':
        return Colors.green;
      case 'ditolak':
      case 'gagal':
        return Colors.red;
      case 'menunggu':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _labelStatus(String status) {
    final nilai = status.toLowerCase();

    if (nilai == 'pending' || nilai == 'menunggu') {
      return 'Menunggu';
    }

    if (nilai == 'approved') return 'Disetujui';
    if (nilai == 'rejected') return 'Ditolak';

    if (status.isEmpty) return 'Selesai';

    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _muatData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [_buildError()],
            )
          : RefreshIndicator(
              onRefresh: _muatData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRingkasan(),
                  const SizedBox(height: 24),
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilter(),
                  const SizedBox(height: 16),
                  if (_transaksiTerfilter.isEmpty)
                    _buildKosong()
                  else
                    ..._transaksiTerfilter.map(_buildKartuTransaksi),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildRingkasan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Transaksi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kartuRingkasan(
                judul: 'Total Setoran',
                nilai: _rupiah(_totalSetoran),
                jumlah: '${_setoran.length} transaksi',
                ikon: Icons.recycling,
                warna: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kartuRingkasan(
                judul: 'Penarikan Disetujui',
                nilai: _rupiah(_totalPenarikanDisetujui),
                jumlah:
                    '${_penarikan.where(_penarikanBerhasil).length} transaksi',
                ikon: Icons.account_balance_wallet_outlined,
                warna: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kartuRingkasan({
    required String judul,
    required String nilai,
    required String jumlah,
    required IconData ikon,
    required Color warna,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warna.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: warna, size: 26),
          const SizedBox(height: 12),
          Text(
            judul,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            nilai,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            jumlah,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    const pilihan = ['Semua', 'Setoran', 'Penarikan'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pilihan.map((pilihan) {
          final aktif = _filter == pilihan;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(pilihan),
              selected: aktif,
              onSelected: (_) {
                setState(() => _filter = pilihan);
              },
              selectedColor: Colors.green.shade100,
              labelStyle: TextStyle(
                color: aktif ? Colors.green.shade900 : Colors.black87,
                fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKartuTransaksi(Map<String, dynamic> item) {
    final jenis = item['jenis'].toString();
    final nominal = (item['nominal'] as num?) ?? 0;
    final status = _labelStatus(item['status']?.toString() ?? '');
    final setoran = jenis == 'Setoran';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (setoran ? Colors.green : Colors.orange).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                setoran
                    ? Icons.recycling
                    : Icons.account_balance_wallet_outlined,
                color: setoran ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['judul']?.toString() ?? jenis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jenis,
                    style: TextStyle(
                      color: setoran ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['keterangan']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTanggal(item['tanggal']?.toString() ?? ''),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _warnaStatus(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: _warnaStatus(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${setoran ? '+' : '-'}${_rupiah(nominal)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: setoran ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKosong() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Riwayat setoran dan penarikan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat riwayat transaksi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _muatData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

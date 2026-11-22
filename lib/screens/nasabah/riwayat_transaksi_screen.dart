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
        ApiService.getRiwayatSetoranNasabah(widget.idNasabah),
        ApiService.getRiwayatPenarikanNasabah(widget.idNasabah),
      ]);

      // Hanya tampilkan setoran milik nasabah yang sedang login.
      final setoranNasabah = hasil[0] as List<SetoranModel>;

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
    final status = (item['status'] ?? '').toString().trim().toLowerCase();

    if (status == 'disetujui' || status == 'approved') return 'Disetujui';
    if (status == 'ditolak' || status == 'rejected') return 'Ditolak';
    if (status == 'selesai' || status == 'completed') return 'Selesai';
    if (['dibatalkan', 'cancelled', 'canceled'].contains(status)) {
      return 'Dibatalkan';
    }
    if (['pending', 'menunggu', 'menunggu verifikasi'].contains(status)) {
      return 'Menunggu';
    }

    return status.isEmpty ? 'Tidak diketahui' : item['status'].toString();
  }

  bool _penarikanBerhasil(Map<String, dynamic> item) {
    final status = _statusPenarikan(item);
    return status == 'Disetujui' || status == 'Selesai';
  }

  List<Map<String, dynamic>> get _semuaTransaksi {
    final List<Map<String, dynamic>> hasil = [];

    for (final item in _setoran) {
      hasil.add({
        'jenis': 'Setoran',
        'data': item,
        'judul': item.namaSampah,
        'tanggal': item.tanggal,
        'nominal': item.totalNilai,
        'status': item.status,
        'keterangan':
            '${(item.totalBerat / 1000).toStringAsFixed(2)} kg • ${item.namaPetugas}',
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
        return AppColors.primary;
      case 'ditolak':
      case 'gagal':
        return Color(0xFFB42318);
      case 'menunggu':
      case 'menunggu verifikasi':
      case 'pending':
        return Color(0xFFD88916);
      case 'dibatalkan':
        return Color(0xFF71847F);
      default:
        return Color(0xFF6B7F7B);
    }
  }

  String _labelStatus(String status) {
    final nilai = status.toLowerCase();

    if (nilai == 'pending' ||
        nilai == 'menunggu' ||
        nilai == 'menunggu verifikasi') {
      return 'Menunggu';
    }

    if (nilai == 'approved') return 'Disetujui';
    if (nilai == 'rejected') return 'Ditolak';
    if (nilai == 'cancelled' || nilai == 'canceled') return 'Dibatalkan';
    if (nilai == 'completed') return 'Selesai';

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
                warna: AppColors.primary,
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
                warna: Color(0xFFD88916),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF71847F)),
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
            style: const TextStyle(fontSize: 11, color: Color(0xFF71847F)),
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
              selectedColor: Color(0xFFD1FAE5),
              labelStyle: TextStyle(
                color: aktif ? AppColors.primary : Colors.black87,
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

    final warna = setoran ? AppColors.primary : Colors.orange;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 9),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: setoran
            ? () {
                final data = item['data'];
                if (data is SetoranModel) {
                  _bukaDetailSetoran(data);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsetsGeometry.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  setoran
                      ? Icons.recycling
                      : Icons.account_balance_wallet_outlined,
                  color: warna,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['judul']?.toString() ?? jenis,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message: 'Status: $status',
                          child: Icon(
                            _ikonStatus(status),
                            color: _warnaStatus(status),
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['keterangan']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTanggal(item['tanggal']?.toString() ?? ''),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                '${setoran
                    ? '+'
                    : (status == 'Disetujui' || status == 'Selesai')
                    ? '-'
                    : ''}${_rupiah(nominal)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: setoran
                      ? AppColors.primary
                      : (status == 'Disetujui' || status == 'Selesai')
                      ? Colors.orange
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _ikonStatus(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'disetujui':
        return Icons.check_circle;
      case 'menunggu':
      case 'pending':
        return Icons.schedule;
      case 'ditolak':
        return Icons.cancel;
      case 'dibatalkan':
        return Icons.remove_circle;
      default:
        return Icons.info_outline;
    }
  }

  void _bukaDetailSetoran(SetoranModel setoran) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(10, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Detail Setoran',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Informasi transaksi setoran Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),

                  const SizedBox(height: 22),

                  _bagianDetail(
                    judul: 'Infomasi Transaksi',
                    child: Column(
                      children: [
                        _barisDetail('ID Transaksi', '#${setoran.idSetoran}'),
                        _barisDetail(
                          'Tanggal Setoran',
                          _formatTanggal(setoran.tanggal),
                        ),
                        _barisDetail('Petugas', setoran.namaPetugas),
                        _barisDetail('Status', _labelStatus(setoran.status)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _bagianDetail(
                    judul: 'Detail Sampah',
                    child: Column(
                      children: [
                        if (setoran.rincian.isEmpty)
                          const Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 12),
                            child: Text(
                              'Rincian sampah tidak tersedia.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        else
                          ...setoran.rincian.map((detail) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.namaSampah,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  _barisDetail(
                                    'Berat',
                                    '${detail.totalBerat.toStringAsFixed(0)} gram',
                                  ),
                                  _barisDetail(
                                    'Harga / Kg',
                                    _rupiah(detail.hargaPerKg),
                                  ),
                                  _barisDetail(
                                    'Subtotal',
                                    _rupiah(detail.totalNilai),
                                    warna: Colors.green,
                                  ),
                                  const Divider(height: 18),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        _barisDetail(
                          'Total Berat',
                          '${setoran.totalBerat.toStringAsFixed(0)} gram',
                        ),
                        const SizedBox(height: 8),
                        _barisDetail(
                          'Total Pendapatan',
                          _rupiah(setoran.totalNilai),
                          warna: Colors.green.shade800,
                          tebal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bagianDetail({required String judul, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _barisDetail(
    String label,
    String nilai, {
    Color? warna,
    bool tebal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: tebal ? FontWeight.bold : FontWeight.w600,
                color: warna ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Riwayat setoran dan penarikan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF71847F)),
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
            color: Color(0xFFB42318),
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
            style: const TextStyle(color: Color(0xFF71847F)),
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

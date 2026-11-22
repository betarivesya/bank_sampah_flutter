import 'package:flutter/material.dart';

import '../../models/laporan_penyerahan_induk_model.dart';
import '../../services/api_service.dart';

class DetailLaporanPenyerahanScreen extends StatefulWidget {
  final int idLaporan;

  const DetailLaporanPenyerahanScreen({super.key, required this.idLaporan});

  @override
  State<DetailLaporanPenyerahanScreen> createState() =>
      _DetailLaporanPenyerahanScreenState();
}

class _DetailLaporanPenyerahanScreenState
    extends State<DetailLaporanPenyerahanScreen> {
  static const Color green = Color(0xFF123D36);

  LaporanPenyerahanIndukModel? _laporan;
  bool _loading = true;
  String? _error;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getDetailLaporanPenyerahan(
        widget.idLaporan,
      );

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

  String _rupiah(double value) {
    final angka = value.round().toString();
    return 'Rp ${angka.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  String _berat(double value) => value.toStringAsFixed(3).replaceAll('.', ',');

  String _tanggal(String value) {
    if (value.length < 10) return value;
    try {
      final date = DateTime.parse(value.substring(0, 10));
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _status(String value) {
    switch (value) {
      case 'siap_diserahkan':
        return 'Siap Diserahkan';
      case 'sudah_diserahkan':
        return 'Sudah Diserahkan';
      case 'draft':
        return 'Draft';
      default:
        return value;
    }
  }

  Future<void> _hapus() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text('Laporan draft ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (setuju != true || _laporan == null) return;

    setState(() => _processing = true);

    try {
      await ApiService.hapusDraftLaporanPenyerahan(_laporan!.idLaporan);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _ubahStatus(String status) async {
    if (_laporan == null) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Status'),
        content: Text(
          status == 'siap_diserahkan'
              ? 'Tandai laporan ini sebagai Siap Diserahkan? '
                    'Setoran yang belum dialokasikan akan dimasukkan ke laporan.'
              : 'Tandai laporan ini sebagai Sudah Diserahkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _processing = true);

    try {
      await ApiService.ubahStatusLaporanPenyerahan(
        id: _laporan!.idLaporan,
        status: status,
      );

      await _muatDetail();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status laporan berhasil diperbarui.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengubah status: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _laporan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Laporan tidak ditemukan.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _muatDetail,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final laporan = _laporan!;
    final isDraft = laporan.status == 'draft';
    final isSiap = laporan.status == 'siap_diserahkan';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        title: const Text('Detail Laporan Penyerahan'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _muatDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Laporan',
                    style: TextStyle(fontWeight: FontWeight.bold, color: green),
                  ),
                  const SizedBox(height: 14),
                  _info('Nomor Laporan', '#${laporan.idLaporan}'),
                  _info('Tanggal Pendataan', _tanggal(laporan.tanggalLaporan)),
                  _info('Status', _status(laporan.status)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Stok Sampah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF0F5F2),
                      ),
                      columns: const [
                        DataColumn(label: Text('No.')),
                        DataColumn(label: Text('Jenis Sampah')),
                        DataColumn(label: Text('Berat Otomatis (Kg)')),
                        DataColumn(label: Text('Berat Final (Kg)')),
                        DataColumn(label: Text('Harga/Kg')),
                        DataColumn(label: Text('Subtotal')),
                      ],
                      rows: List.generate(laporan.detailLaporan.length, (
                        index,
                      ) {
                        final item = laporan.detailLaporan[index];
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(item.namaSampah)),
                            DataCell(Text(_berat(item.beratOtomatis))),
                            DataCell(Text(_berat(item.beratFinal))),
                            DataCell(Text(_rupiah(item.hargaPerKg))),
                            DataCell(Text(_rupiah(item.subtotal))),
                          ],
                        );
                      }),
                    ),
                  ),
                  const Divider(height: 25),
                  _info('Total Berat', '${_berat(laporan.totalBerat)} Kg'),
                  _info('Total Nominal', _rupiah(laporan.totalNominal)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _panel(
              child: Column(
                children: [
                  if (isDraft) ...[
                    _actionButton('Edit', Icons.edit_outlined, green, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Halaman Edit akan disambungkan berikutnya.',
                          ),
                        ),
                      );
                    }),
                    _actionButton(
                      'Hapus',
                      Icons.delete_outline,
                      Colors.red,
                      _processing ? null : _hapus,
                    ),
                    _actionButton(
                      'Siap Diserahkan',
                      Icons.inventory_2_outlined,
                      const Color(0xFF23619A),
                      _processing ? null : () => _ubahStatus('siap_diserahkan'),
                    ),
                  ],
                  if (isSiap)
                    _actionButton(
                      'Sudah Diserahkan',
                      Icons.check_circle_outline,
                      green,
                      _processing
                          ? null
                          : () => _ubahStatus('sudah_diserahkan'),
                    ),
                  _actionButton(
                    'Export Excel',
                    Icons.file_download_outlined,
                    const Color(0xFF16834B),
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fungsi unduh Excel akan disambungkan berikutnya.',
                          ),
                        ),
                      );
                    },
                  ),
                  _actionButton(
                    'Cetak',
                    Icons.print_outlined,
                    const Color(0xFF23619A),
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fungsi cetak akan disambungkan berikutnya.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

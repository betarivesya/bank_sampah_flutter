import 'package:flutter/material.dart';

import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../models/setoran_model.dart';
import '../../services/api_service.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  // Menentukan warna utama dan latar belakang halaman laporan.
  static const Color _green = Color(0xFF075B4F);
  static const Color _background = Color(0xFFF4F7F6);

  // Menyimpan data setoran, status pemuatan, dan pesan kesalahan.
  List<SetoranModel> _setoran = [];
  bool _loading = true;
  String? _error;

  // Menyimpan tanggal mulai dan akhir untuk memfilter laporan.
  DateTime? _tanggalMulai;
  DateTime? _tanggalAkhir;

  @override
  void initState() {
    super.initState();
    _muatSetoran();
  }

  // Mengambil data setoran dari API saat halaman dibuka atau dimuat ulang.
  Future<void> _muatSetoran() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getSetoran();

      if (!mounted) return;

      setState(() {
        _setoran = data;
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

  // Mengubah teks tanggal dari API menjadi DateTime agar bisa difilter.
  DateTime? _parseTanggal(String value) {
    if (value.isEmpty) return null;

    try {
      final tanggal = value.length >= 10 ? value.substring(0, 10) : value;

      return DateTime.parse(tanggal);
    } catch (_) {
      return null;
    }
  }

  // Mengambil data setoran yang tanggalnya sesuai dengan rentang filter.
  List<SetoranModel> get _setoranTerfilter {
    return _setoran.where((setoran) {
      final tanggal = _parseTanggal(setoran.tanggal);

      if (tanggal == null) return false;

      final hari = DateTime(tanggal.year, tanggal.month, tanggal.day);

      if (_tanggalMulai != null) {
        final mulai = DateTime(
          _tanggalMulai!.year,
          _tanggalMulai!.month,
          _tanggalMulai!.day,
        );

        if (hari.isBefore(mulai)) return false;
      }

      if (_tanggalAkhir != null) {
        final akhir = DateTime(
          _tanggalAkhir!.year,
          _tanggalAkhir!.month,
          _tanggalAkhir!.day,
        );

        if (hari.isAfter(akhir)) return false;
      }

      return true;
    }).toList();
  }

  // Menampilkan tanggal dalam format hari/bulan/tahun.
  String _formatTanggal(DateTime? tanggal) {
    if (tanggal == null) return 'Pilih tanggal';

    final hari = tanggal.day.toString().padLeft(2, '0');
    final bulan = tanggal.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${tanggal.year}';
  }

  // Memformat tanggal dari data setoran agar tampil seragam.
  String _formatTanggalData(String value) {
    return _formatTanggal(_parseTanggal(value));
  }

  // Mengubah angka nominal menjadi format Rupiah dengan pemisah ribuan.
  String _formatRupiah(num nilai) {
    final angka = nilai.round().toString();

    final hasil = angka.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return 'Rp $hasil';
  }

  // Menampilkan berat sampah dengan dua angka desimal dan satuan kilogram.
  String _formatBerat(num berat) {
    return '${berat.toStringAsFixed(2).replaceAll('.', ',')} kg';
  }

  // Menampilkan kalender untuk memilih tanggal mulai atau tanggal akhir.
  Future<void> _pilihTanggal({required bool tanggalMulai}) async {
    final tanggalSaatIni = tanggalMulai ? _tanggalMulai : _tanggalAkhir;

    final tanggalDipilih = await showDatePicker(
      context: context,
      initialDate: tanggalSaatIni ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: tanggalMulai ? 'Pilih tanggal mulai' : 'Pilih tanggal akhir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (tanggalDipilih == null || !mounted) return;

    setState(() {
      if (tanggalMulai) {
        _tanggalMulai = tanggalDipilih;

        if (_tanggalAkhir != null && _tanggalAkhir!.isBefore(tanggalDipilih)) {
          _tanggalAkhir = tanggalDipilih;
        }
      } else {
        _tanggalAkhir = tanggalDipilih;

        if (_tanggalMulai != null && _tanggalMulai!.isAfter(tanggalDipilih)) {
          _tanggalMulai = tanggalDipilih;
        }
      }
    });
  }

  // Membuat file Excel
  Future<void> _exportExcel() async {
    final data = _setoranTerfilter;

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    try {
      final excel = Excel.createExcel();

      final sheet = excel['Sheet1'];
      excel.rename('Sheet1', 'Laporan Setoran');

      sheet.appendRow([
        TextCellValue('ID Setoran'),
        TextCellValue('Tanggal'),
        TextCellValue('Nama Nasabah'),
        TextCellValue('Jenis Sampah'),
        TextCellValue('Berat (kg)'),
        TextCellValue('Total Nominal'),
        TextCellValue('Nama Petugas'),
        TextCellValue('Status'),
      ]);

      for (final setoran in data) {
        sheet.appendRow([
          TextCellValue(setoran.idSetoran.toString()),
          TextCellValue(_formatTanggalData(setoran.tanggal)),
          TextCellValue(setoran.namaNasabah),
          TextCellValue(setoran.namaSampah),
          DoubleCellValue(setoran.totalBerat),
          DoubleCellValue(setoran.totalNilai),
          TextCellValue(setoran.namaPetugas),
          TextCellValue(setoran.status.isEmpty ? '-' : setoran.status),
        ]);
      }

      debugPrint('Jumlah data terfilter: ${data.length}');
      debugPrint('Nama sheet: ${excel.tables.keys.toList()}');
      debugPrint('Jumlah baris Excel: ${sheet.maxRows}');
      debugPrint('Jumlah kolom Excel: ${sheet.maxColumns}');

      final bytes = excel.encode();

      debugPrint('Ukuran file Excel: ${bytes?.length ?? 0} bytes');

      if (bytes == null || bytes.isEmpty) {
        throw Exception('File Excel gagal dibuat atau kosong.');
      }

      final direktori = await getApplicationDocumentsDirectory();
      final waktu = DateTime.now();
      final namaFile =
          'laporan_setoran_${waktu.year}'
          '${waktu.month.toString().padLeft(2, '0')}'
          '${waktu.day.toString().padLeft(2, '0')}_'
          '${waktu.hour.toString().padLeft(2, '0')}'
          '${waktu.minute.toString().padLeft(2, '0')}.xlsx';

      final file = File('${direktori.path}/$namaFile');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File Excel berhasil dibuat.'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () async {
              await OpenFilex.open(file.path);
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengekspor Excel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung total berat dan nominal berdasarkan data yang sudah difilter.
    final data = _setoranTerfilter;

    final totalBerat = data.fold<double>(
      0,
      (total, item) => total + item.totalBerat,
    );

    final totalNominal = data.fold<double>(
      0,
      (total, item) => total + item.totalNilai,
    );

    return Container(
      color: _background,
      child: RefreshIndicator(
        color: _green,
        onRefresh: _muatSetoran,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator(color: _green)),
                ],
              )
            : _error != null
            ? _buildError()
            : _buildLaporan(
                data: data,
                totalBerat: totalBerat,
                totalNominal: totalNominal,
              ),
      ),
    );
  }

  // Menampilkan pesan kesalahan dan tombol untuk mencoba memuat data kembali.
  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        const Text(
          'Gagal memuat laporan',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            onPressed: _muatSetoran,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ),
      ],
    );
  }

  // Menampilkan filter tanggal, ringkasan laporan, dan daftar transaksi setoran.
  Widget _buildLaporan({
    required List<SetoranModel> data,
    required double totalBerat,
    required double totalNominal,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const Text(
          'Laporan Setoran',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF173B35),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Daftar transaksi setoran sampah yang tercatat dalam sistem.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),

        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Laporan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _tombolTanggal(
                      label: 'Tanggal Mulai',
                      value: _formatTanggal(_tanggalMulai),
                      onTap: () => _pilihTanggal(tanggalMulai: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tombolTanggal(
                      label: 'Tanggal Akhir',
                      value: _formatTanggal(_tanggalAkhir),
                      onTap: () => _pilihTanggal(tanggalMulai: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      // Memperbarui tampilan laporan sesuai tanggal yang dipilih.
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('Tampilkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      // Mengekspor data laporan
                      onPressed: _exportExcel,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _kartuRingkasan(
          icon: Icons.receipt_long_outlined,
          judul: 'Total Transaksi',
          nilai: '${data.length}',
          warna: const Color(0xFF2E8B72),
        ),

        const SizedBox(height: 9),

        _kartuRingkasan(
          icon: Icons.scale_outlined,
          judul: 'Total Berat Sampah',
          nilai: _formatBerat(totalBerat),
          warna: const Color(0xFF3878B8),
        ),

        const SizedBox(height: 9),

        _kartuRingkasan(
          icon: Icons.payments_outlined,
          judul: 'Total Nominal',
          nilai: _formatRupiah(totalNominal),
          warna: const Color(0xFFD18A25),
        ),

        const SizedBox(height: 18),

        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Setoran',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                '${data.length} transaksi ditemukan',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 12),

              if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 42,
                          color: Colors.black38,
                        ),
                        SizedBox(height: 8),
                        Text('Tidak ada setoran pada periode ini'),
                      ],
                    ),
                  ),
                )
              else
                ...data.map(_kartuSetoran),
            ],
          ),
        ),
      ],
    );
  }

  // Membuat panel putih dengan sudut membulat untuk mengelompokkan komponen.
  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
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

  // Membuat tombol kalender untuk memilih tanggal pada filter laporan.
  Widget _tombolTanggal({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD7E0DD)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: _green,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Membuat kartu ringkasan untuk menampilkan jumlah transaksi, berat, atau nominal.
  Widget _kartuRingkasan({
    required IconData icon,
    required String judul,
    required String nilai,
    required Color warna,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: warna, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 5),
                Text(
                  nilai,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF153C35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Membuat kartu yang menampilkan detail setiap transaksi setoran.
  Widget _kartuSetoran(SetoranModel setoran) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID #${setoran.idSetoran}',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTanggalData(setoran.tanggal),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            setoran.namaNasabah,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            setoran.namaSampah,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.scale_outlined, size: 16, color: _green),
              const SizedBox(width: 5),
              Text(
                _formatBerat(setoran.totalBerat),
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatRupiah(setoran.totalNilai),
                style: const TextStyle(
                  color: _green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 15, color: Colors.black45),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Petugas: ${setoran.namaPetugas}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              Text(
                setoran.status.isEmpty ? '-' : setoran.status,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

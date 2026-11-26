import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminRiwayatTransaksiScreen extends StatefulWidget {
  const AdminRiwayatTransaksiScreen({super.key});

  @override
  State<AdminRiwayatTransaksiScreen> createState() =>
      _AdminRiwayatTransaksiScreenState();
}

class _AdminRiwayatTransaksiScreenState
    extends State<AdminRiwayatTransaksiScreen> {
  static const Color green = Color(0xFF176B55);
  static const Color darkGreen = Color(0xFF123D36);
  static const Color orange = Color(0xFFE58A26);
  static const Color background = Color(0xFFF4F8F6);
  static const Color grey = Color(0xFF71847F);

  final _nasabahController = TextEditingController();
  final _petugasController = TextEditingController();

  DateTime? _tanggalMulai;
  DateTime? _tanggalAkhir;

  String _jenisTransaksi = 'Semua';

  List<Map<String, dynamic>> _transaksi = [];

  bool _loading = true;
  bool _exporting = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  static const int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _muatTransaksi();
  }

  @override
  void dispose() {
    _nasabahController.dispose();
    _petugasController.dispose();
    super.dispose();
  }

  String _formatTanggal(DateTime tanggal) {
    return '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
  }

  String _formatWaktu(dynamic value) {
    if (value == null) return '-';

    final tanggal = DateTime.tryParse(value.toString());

    if (tanggal == null) return value.toString();

    return '${tanggal.day.toString().padLeft(2, '0')}/'
        '${tanggal.month.toString().padLeft(2, '0')}/'
        '${tanggal.year} '
        '${tanggal.hour.toString().padLeft(2, '0')}:'
        '${tanggal.minute.toString().padLeft(2, '0')}';
  }

  String _formatRupiah(dynamic value) {
    final nominal = double.tryParse(value?.toString() ?? '') ?? 0;
    final angka = nominal.toStringAsFixed(0);
    final hasil = angka.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $hasil';
  }

  String _formatBerat(dynamic value) {
    if (value == null || value.toString() == '-') return '-';

    final berat = double.tryParse(value.toString());
    if (berat == null) return value.toString();

    final hasil = berat == berat.roundToDouble()
        ? berat.toStringAsFixed(0)
        : berat.toStringAsFixed(2);

    return '$hasil gram';
  }

  bool get _filterTanggalValid {
    return _tanggalMulai == null ||
        _tanggalAkhir == null ||
        !_tanggalAkhir!.isBefore(_tanggalMulai!);
  }

  Future<void> _muatTransaksi({int page = 1}) async {
    if (!_filterTanggalValid) {
      _pesan('Tanggal akhir tidak boleh sebelum tanggal awal.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getAdminRiwayatTransaksi(
        tanggalMulai: _tanggalMulai == null
            ? null
            : _formatTanggal(_tanggalMulai!),
        tanggalAkhir: _tanggalAkhir == null
            ? null
            : _formatTanggal(_tanggalAkhir!),
        namaNasabah: _nasabahController.text,
        namaPetugas: _petugasController.text,
        jenisTransaksi: _jenisTransaksi,
        page: page,
        perPage: _perPage,
      );

      final dynamic items = response['data'];

      if (items is! List) {
        throw Exception('Format data riwayat transaksi tidak sesuai.');
      }

      if (!mounted) return;

      setState(() {
        _transaksi = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        _currentPage =
            int.tryParse(response['current_page']?.toString() ?? '') ?? page;

        _lastPage = int.tryParse(response['last_page']?.toString() ?? '') ?? 1;

        _total =
            int.tryParse(response['total']?.toString() ?? '') ??
            _transaksi.length;

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

  Future<void> _pilihTanggal(bool tanggalAwal) async {
    final sekarang = DateTime.now();

    final hasil = await showDatePicker(
      context: context,
      initialDate: tanggalAwal
          ? (_tanggalMulai ?? sekarang)
          : (_tanggalAkhir ?? _tanggalMulai ?? sekarang),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: green,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hasil == null || !mounted) return;

    setState(() {
      if (tanggalAwal) {
        _tanggalMulai = hasil;
        if (_tanggalAkhir != null && _tanggalAkhir!.isBefore(hasil)) {
          _tanggalAkhir = null;
        }
      } else {
        _tanggalAkhir = hasil;
      }
    });
  }

  void _resetFilter() {
    _nasabahController.clear();
    _petugasController.clear();

    setState(() {
      _tanggalMulai = null;
      _tanggalAkhir = null;
      _jenisTransaksi = 'Semua';
    });

    _muatTransaksi();
  }

  Future<void> _exportExcel() async {
    if (!_filterTanggalValid) {
      _pesan('Periksa kembali rentang tanggal.');
      return;
    }

    setState(() => _exporting = true);

    try {
      final path = await ApiService.downloadExcelRekapSetoran(
        tanggalMulai: _tanggalMulai == null
            ? null
            : _formatTanggal(_tanggalMulai!),
        tanggalAkhir: _tanggalAkhir == null
            ? null
            : _formatTanggal(_tanggalAkhir!),
      );

      if (!mounted) return;

      _pesan('Excel berhasil disimpan di:\n$path');
    } catch (e) {
      if (!mounted) return;

      _pesan(
        'Gagal mengunduh Excel: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _pesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(pesan), behavior: SnackBarBehavior.floating),
      );
  }

  bool _isSetoran(Map<String, dynamic> item) {
    return item['jenis_transaksi']?.toString().toLowerCase() == 'setoran';
  }

  Color _warnaTransaksi(Map<String, dynamic> item) {
    return _isSetoran(item) ? green : orange;
  }

  Color _warnaLatarTransaksi(Map<String, dynamic> item) {
    return _isSetoran(item) ? const Color(0xFFE3F3EC) : const Color(0xFFFFF0DD);
  }

  String _labelStatus(dynamic status) {
    if (status == null || status.toString().isEmpty) return '-';

    final value = status.toString().toLowerCase();

    if (value == 'approved') return 'Approved';
    if (value == 'selesai') return 'Selesai';
    if (value == 'pending') return 'Pending';
    if (value == 'rejected') return 'Ditolak';

    return status.toString();
  }

  Widget _tanggalField({
    required String label,
    required DateTime? tanggal,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 43,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDCE5E1)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tanggal == null
                          ? 'Pilih tanggal'
                          : _formatWaktu(_formatTanggal(tanggal))
                                .split(' ')
                                .first,
                      style: TextStyle(
                        fontSize: 11,
                        color: tanggal == null ? grey : darkGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tanggal != null && onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(Icons.close, size: 15, color: grey),
                    )
                  else
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: grey,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E8E4)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputFilter(
            label: 'Nama Nasabah',
            controller: _nasabahController,
            hint: 'Cari nama nasabah...',
          ),
          const SizedBox(height: 10),
          _inputFilter(
            label: 'Nama Petugas',
            controller: _petugasController,
            hint: 'Cari nama petugas...',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tanggalField(
                label: 'Dari Tanggal',
                tanggal: _tanggalMulai,
                onTap: () => _pilihTanggal(true),
                onClear: () => setState(() => _tanggalMulai = null),
              ),
              const SizedBox(width: 9),
              _tanggalField(
                label: 'Sampai Tanggal',
                tanggal: _tanggalAkhir,
                onTap: () => _pilihTanggal(false),
                onClear: () => setState(() => _tanggalAkhir = null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Jenis Transaksi',
            style: TextStyle(
              fontSize: 11,
              color: grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _jenisTransaksi,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFDCE5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFDCE5E1)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Semua', child: Text('Semua Transaksi')),
              DropdownMenuItem(value: 'Setoran', child: Text('Setoran')),
              DropdownMenuItem(value: 'Penarikan', child: Text('Penarikan')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _jenisTransaksi = value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _muatTransaksi(),
                  icon: const Icon(Icons.search, size: 17),
                  label: const Text('Cari'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 39),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _resetFilter,
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: grey,
                    minimumSize: const Size(0, 39),
                    side: const BorderSide(color: Color(0xFFDCE5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputFilter({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 43,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFDCE5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFDCE5E1)),
              ),
            ),
            onSubmitted: (_) => _muatTransaksi(),
          ),
        ),
      ],
    );
  }

  Widget _kartuTransaksi(Map<String, dynamic> item) {
    final setoran = _isSetoran(item);
    final warna = _warnaTransaksi(item);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: setoran ? () => _bukaDetailSetoran(item) : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EEEA)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          setoran
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          size: 15,
                          color: warna,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          setoran ? 'Setoran' : 'Penarikan',
                          style: TextStyle(
                            color: warna,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatWaktu(item['waktu']),
                    style: const TextStyle(fontSize: 10, color: grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _barisInfo('Nasabah', item['nasabah']?.toString() ?? '-'),
              const SizedBox(height: 5),
              _barisInfo('Petugas', item['petugas']?.toString() ?? '-'),
              const Divider(height: 17, color: Color(0xFFEDF1EF)),
              Row(
                children: [
                  Expanded(
                    child: _nilaiRingkas(
                      'Berat Total',
                      _formatBerat(item['berat']),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _nilaiRingkas(
                      'Nominal',
                      _formatRupiah(item['nominal']),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              if (setoran) ...[
                const SizedBox(height: 7),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Ketuk untuk melihat detail',
                    style: TextStyle(fontSize: 9, color: grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _barisInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Text(label, style: const TextStyle(fontSize: 10, color: grey)),
        ),
        const Text(': ', style: TextStyle(fontSize: 10, color: grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _nilaiRingkas(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: grey)),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 12,
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _bukaDetailSetoran(Map<String, dynamic> item) {
    final detail = item['detail_sampah'];

    final List<Map<String, dynamic>> daftarDetail = detail is List
        ? detail
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(19, 12, 19, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detail Transaksi Setoran',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F3EC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Setoran',
                          style: TextStyle(
                            color: green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _detailBaris('Waktu', _formatWaktu(item['waktu'])),
                  _detailBaris(
                    'Nama Nasabah',
                    item['nasabah']?.toString() ?? '-',
                  ),
                  _detailBaris(
                    'Nama Petugas',
                    item['petugas']?.toString() ?? '-',
                  ),
                  _detailBaris('Status', _labelStatus(item['status'])),
                  const SizedBox(height: 17),
                  const Text(
                    'Rincian Jenis Sampah',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (daftarDetail.isEmpty)
                    const Text(
                      'Rincian jenis sampah tidak tersedia.',
                      style: TextStyle(color: grey, fontSize: 12),
                    )
                  else
                    ...daftarDetail.map((sampah) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.recycling, size: 18, color: green),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                sampah['nama_sampah']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: darkGreen,
                                ),
                              ),
                            ),
                            Text(
                              _formatBerat(sampah['berat']),
                              style: const TextStyle(fontSize: 11, color: grey),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F3EC),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Column(
                      children: [
                        _detailBaris(
                          'Berat Total',
                          _formatBerat(item['berat']),
                          bold: true,
                        ),
                        const Divider(color: Color(0xFFC9E3D7)),
                        _detailBaris(
                          'Total Nominal',
                          _formatRupiah(item['nominal']),
                          bold: true,
                          valueColor: green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailBaris(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: grey),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? darkGreen,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    if (_lastPage <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1 && !_loading
              ? () => _muatTransaksi(page: _currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          'Halaman $_currentPage dari $_lastPage',
          style: const TextStyle(fontSize: 11, color: grey),
        ),
        IconButton(
          onPressed: _currentPage < _lastPage && !_loading
              ? () => _muatTransaksi(page: _currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _isiDaftar() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 55),
        child: Center(child: CircularProgressIndicator(color: green)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 35),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38, color: grey),
            const SizedBox(height: 9),
            const Text(
              'Gagal memuat riwayat transaksi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _muatTransaksi(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_transaksi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 42, color: grey),
            SizedBox(height: 10),
            Text(
              'Tidak ada transaksi ditemukan.',
              style: TextStyle(fontSize: 12, color: grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ..._transaksi.map(_kartuTransaksi),
        const SizedBox(height: 5),
        Text(
          'Menampilkan ${_transaksi.length} dari $_total transaksi',
          style: const TextStyle(fontSize: 10, color: grey),
        ),
        _pagination(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: RefreshIndicator(
        color: green,
        onRefresh: () => _muatTransaksi(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(15, 17, 15, 30),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Daftar seluruh transaksi setoran dan penarikan nasabah.',
                        style: TextStyle(fontSize: 10, color: grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_total transaksi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Transaksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Semua riwayat transaksi yang telah tercatat dalam sistem.',
                    style: TextStyle(fontSize: 10, color: grey),
                  ),
                  const Divider(height: 22),
                  _filterSection(),
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportExcel,
                      icon: _exporting
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.file_download_outlined, size: 17),
                      label: Text(
                        _exporting ? 'Mengunduh...' : 'Export Laporan Setoran',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _isiDaftar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

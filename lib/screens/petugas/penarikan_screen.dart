import 'package:bank_sampah_flutter/screens/admin/admin_drawer.dart';
import 'package:bank_sampah_flutter/screens/petugas/petugas_drawer.dart';
import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/services/api_service.dart';

class PenarikanScreen extends StatefulWidget {
  final int idPetugas;

  const PenarikanScreen({super.key, required this.idPetugas});

  @override
  State<PenarikanScreen> createState() => _PenarikanScreenState();
}

class _PenarikanScreenState extends State<PenarikanScreen> {
  static const int _pageSize = 20;
  final TextEditingController _kodeController = TextEditingController();
  final FocusNode _kodeFocusNode = FocusNode();

  Map<String, dynamic>? _pengajuan;
  bool _loading = false;
  bool _memproses = false;
  bool _saldoCukup = false;
  String? _pesan;
  bool _pesanError = false;

  List<Map<String, dynamic>> _daftarPenarikan = [];
  DateTime? _dariTanggal;
  DateTime? _sampaiTanggal;
  bool _memuatRiwayat = false;

  int _currentPage = 1;
  int _totalPages = 1;

  static const Color hijau = Color(0xFF166534);
  static const Color hijauMuda = Color(0xFFDCFCE7);
  static const Color latar = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _muatDaftarPenarikan();
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _kodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _muatDaftarPenarikan({int page = 1}) async {
    setState(() {
      _memuatRiwayat = true;
      _currentPage = page;
    });

    try {
      final result = await ApiService.getPetugasPenarikanPage(
        status: 'Disetujui',
        dariTanggal: _formatTanggalApi(_dariTanggal),
        sampaiTanggal: _formatTanggalApi(_sampaiTanggal),
        page: page,
        perPage: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _daftarPenarikan = result.items;
        _totalPages = result.lastPage;
      });
    } catch (e) {
      if (!mounted) return;

      _tampilkanPesan(_bersihkanError(e), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _memuatRiwayat = false;
        });
      }
    }
  }

  Future<void> _validasiKode() async {
    final kode = _kodeController.text.trim();

    if (kode.isEmpty) {
      setState(() {
        _pesan = 'Masukkan kode verifikasi dari nasabah.';
        _pesanError = true;
        _pengajuan = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _pesan = null;
      _pengajuan = null;
    });

    try {
      final data = await ApiService.cariPenarikanPetugas(kode);

      if (!mounted) return;

      final saldo = _angka(data['saldo']);
      final nominal = _angka(data['nominal']);
      final status = _normalisasiStatus(data['status']);

      setState(() {
        _pengajuan = data;
        _saldoCukup =
            data['saldo_cukup'] == true ||
            (status == 'pending' && saldo >= nominal);
        _pesan = status == 'pending'
            ? 'Pengajuan berhasil ditemukan.'
            : 'Pengajuan ini sudah ${_labelStatus(status).toLowerCase()}.';
        _pesanError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _pengajuan = null;
        _pesan = _bersihkanError(e);
        _pesanError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _prosesPenarikan(String statusBaru) async {
    final pengajuan = _pengajuan;

    if (pengajuan == null) return;

    final statusSaatIni = _normalisasiStatus(pengajuan['status']);

    if (statusSaatIni != 'pending') {
      _tampilkanPesan('Pengajuan ini sudah diproses sebelumnya.', error: true);
      return;
    }

    if (statusBaru == 'Disetujui' && !_saldoCukup) {
      _tampilkanPesan('Saldo nasabah tidak mencukupi.', error: true);
      return;
    }

    final nominal = _angka(pengajuan['nominal']);

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          statusBaru == 'Disetujui' ? 'Setujui Penarikan?' : 'Tolak Penarikan?',
        ),
        content: Text(
          statusBaru == 'Disetujui'
              ? 'Setujui penarikan sebesar ${formatRupiah(nominal)}? '
                    'Saldo nasabah akan dipotong setelah persetujuan berhasil.'
              : 'Yakin ingin menolak pengajuan penarikan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: statusBaru == 'Disetujui' ? hijau : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(statusBaru),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    setState(() {
      _memproses = true;
      _pesan = null;
    });

    try {
      final idPenarikan = int.tryParse(pengajuan['id_penarikan'].toString());

      if (idPenarikan == null) {
        throw Exception('ID pengajuan penarikan tidak valid.');
      }

      final hasil = await ApiService.prosesPenarikanPetugas(
        idPenarikan: idPenarikan,
        idPetugas: widget.idPetugas,
        status: statusBaru,
        kodeVerifikasi: _kodeController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _pengajuan!['status'] = statusBaru;
        _pesan = hasil['message']?.toString() ?? 'Pengajuan berhasil diproses.';
        _pesanError = false;
      });

      _tampilkanPesan(
        hasil['message']?.toString() ?? 'Pengajuan berhasil diproses.',
      );

      await _muatDaftarPenarikan();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _pesan = _bersihkanError(e);
        _pesanError = true;
      });

      _tampilkanPesan(_bersihkanError(e), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _memproses = false;
        });
      }
    }
  }

  void _pilihPengajuan(Map<String, dynamic> data) {
    setState(() {
      _pengajuan = Map<String, dynamic>.from(data);
      _kodeController.text = data['kode_verifikasi']?.toString() ?? '';
      _saldoCukup =
          data['saldo_cukup'] == true ||
          _angka(data['saldo']) >= _angka(data['nominal']);
      _pesan = null;
    });

    _validasiKode();
  }

  void _tampilkanPesan(String pesan, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: error ? Colors.red.shade700 : hijau,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // FILTER TANGGAL
  Future<void> _pilihTanggal({required bool tanggalMulai}) async {
    final sekarang = DateTime.now();

    final tanggal = await showDatePicker(
      context: context,
      initialDate: tanggalMulai
          ? (_dariTanggal ?? _sampaiTanggal ?? sekarang)
          : (_sampaiTanggal ?? _dariTanggal ?? sekarang),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: tanggalMulai ? 'Pilih Tanggal Awal' : 'Pilih Tanggal Akhir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (tanggal == null || !mounted) return;

    setState(() {
      if (tanggalMulai) {
        _dariTanggal = tanggal;

        if (_sampaiTanggal != null && _sampaiTanggal!.isBefore(tanggal)) {
          _sampaiTanggal = tanggal;
        }
      } else {
        _sampaiTanggal = tanggal;

        if (_dariTanggal != null && tanggal.isBefore(_dariTanggal!)) {
          _dariTanggal = tanggal;
        }
      }
    });
  }

  void _resetFilterTanggal() {
    setState(() {
      _dariTanggal = null;
      _sampaiTanggal = null;
    });

    _muatDaftarPenarikan();
  }

  String? _formatTanggalApi(DateTime? tanggal) {
    if (tanggal == null) return '';

    final tahun = tanggal.year.toString().padLeft(4, '0');
    final bulan = tanggal.month.toString().padLeft(2, '0');
    final hari = tanggal.day.toString().padLeft(2, '0');

    return '$tahun-$bulan-$hari';
  }

  String _bersihkanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  double _angka(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();
    return double.tryParse(nilai?.toString() ?? '') ?? 0;
  }

  String _normalisasiStatus(dynamic status) {
    return status?.toString().trim().toLowerCase() ?? '';
  }

  String _labelStatus(dynamic status) {
    switch (_normalisasiStatus(status)) {
      case 'pending':
      case 'menunggu':
      case 'menunggu verifikasi':
        return 'Menunggu Verifikasi';

      case 'approved':
      case 'disetujui':
        return 'Disetujui';

      case 'rejected':
      case 'ditolak':
        return 'Ditolak';

      case 'completed':
      case 'selesai':
        return 'Selesai';

      case 'cancelled':
      case 'canceled':
      case 'dibatalkan':
        return 'Dibatalkan';

      default:
        return status?.toString() ?? '-';
    }
  }

  Color _warnaStatus(dynamic status) {
    switch (_normalisasiStatus(status)) {
      case 'pending':
      case 'menunggu':
      case 'menunggu verifikasi':
        return Color(0xFF9A5700);

      case 'approved':
      case 'disetujui':
      case 'completed':
      case 'selesai':
        return const Color(0xFF146C2E);

      case 'rejected':
      case 'ditolak':
        return const Color(0xFFB42318);

      case 'cancelled':
      case 'canceled':
      case 'dibatalkan':
        return const Color(0xFF424242);

      default:
        return const Color(0xFF37474F);
    }
  }

  String formatRupiah(num nilai) {
    final angka = nilai.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < angka.length; i++) {
      buffer.write(angka[i]);

      final sisa = angka.length - i - 1;
      if (sisa > 0 && sisa % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp${buffer.toString()}';
  }

  String formatTanggal(dynamic tanggal) {
    if (tanggal == null || tanggal.toString().isEmpty) return '-';

    final date = DateTime.tryParse(tanggal.toString());
    if (date == null) return tanggal.toString();

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: latar,
      child: RefreshIndicator(
        onRefresh: _muatDaftarPenarikan,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFormValidasi(),
            if (_pesan != null) ...[const SizedBox(height: 12), _buildPesan()],
            if (_pengajuan != null) ...[
              const SizedBox(height: 20),
              _buildDetailPengajuan(),
            ],
            const SizedBox(height: 28),
            _buildDaftarPengajuan(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verifikasi Penarikan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Periksa pengajuan nasabah dan kelola riwayat penarikan.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFormValidasi() {
    return _kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hijauMuda,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AdminDrawer.darkGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validasi Pengajuan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Verifikasi penarikan nasabah',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Masukkan Kode Verifikasi',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan 6 digit kode yang diberikan kepada nasabah.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Enam kotak kode visual
          GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(_kodeFocusNode);
            },
            child: Stack(
              children: [
                Row(
                  children: List.generate(6, (index) {
                    final kode = _kodeController.text;
                    final isi = index < kode.length ? kode[index] : '';

                    return Expanded(
                      child: Container(
                        height: 54,
                        margin: EdgeInsets.only(right: index == 5 ? 0 : 7),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: index == kode.length
                                ? AdminDrawer.darkGreen
                                : Colors.grey.shade400,
                            width: index == kode.length ? 1.8 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isi.isEmpty ? '-' : isi,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: AdminDrawer.darkGreen,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _kodeController,
                      focusNode: _kodeFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.search,
                      maxLength: 6,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _validasiKode(),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _validasiKode,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? 'Memvalidasi...' : 'Validasi Pengajuan'),
              style: FilledButton.styleFrom(
                backgroundColor: PetugasDrawer.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesan() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pesanError ? Colors.red.withValues(alpha: 0.08) : hijauMuda,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _pesanError ? Icons.error_outline : Icons.check_circle_outline,
            color: _pesanError ? Colors.red : hijau,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _pesan!,
              style: TextStyle(
                color: _pesanError ? Colors.red.shade800 : hijau,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPengajuan() {
    final data = _pengajuan!;
    final status = _normalisasiStatus(data['status']);
    final nominal = _angka(data['nominal']);
    final saldo = _angka(data['saldo']);
    final masihPending = status == 'pending';

    return _kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Detail Pengajuan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _warnaStatus(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labelStatus(status),
                  style: TextStyle(
                    color: _warnaStatus(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _barisDetail(
            'Kode Pengajuan',
            data['kode_penarikan']?.toString() ?? '-',
          ),
          _barisDetail('Nama Nasabah', data['nama_nasabah']?.toString() ?? '-'),
          _barisDetail('Nomor Telepon', data['no_telepon']?.toString() ?? '-'),
          _barisDetail(
            'Tanggal Pengajuan',
            formatTanggal(data['tgl_pengajuan']),
          ),
          _barisDetail('Saldo Saat Ini', formatRupiah(saldo)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hijauMuda,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nominal Penarikan',
                    style: TextStyle(color: hijau, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatRupiah(nominal),
                  style: const TextStyle(
                    color: hijau,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _saldoCukup ? Icons.check_circle : Icons.cancel,
                color: _saldoCukup ? hijau : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _saldoCukup
                      ? 'Saldo nasabah mencukupi.'
                      : 'Saldo nasabah tidak mencukupi.',
                  style: TextStyle(
                    color: _saldoCukup ? hijau : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (masihPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _memproses
                        ? null
                        : () => _prosesPenarikan('Ditolak'),
                    icon: const Icon(Icons.close),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _memproses || !_saldoCukup
                        ? null
                        : () => _prosesPenarikan('Disetujui'),
                    icon: _memproses
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_memproses ? 'Memproses...' : 'Setujui'),
                    style: FilledButton.styleFrom(
                      backgroundColor: hijau,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaftarPengajuan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Riwayat Penarikan Terverifikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        // Filter Tanggal
        Row(
          children: [
            Expanded(
              child: _fieldTanggal(
                label: 'Dari Tanggal',
                tanggal: _dariTanggal,
                onTap: () => _pilihTanggal(tanggalMulai: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _fieldTanggal(
                label: 'Sampai Tanggal',
                tanggal: _sampaiTanggal,
                onTap: () => _pilihTanggal(tanggalMulai: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tombol filter dan reset
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _memuatRiwayat ? null : () => _muatDaftarPenarikan(),
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Filter'),
                style: FilledButton.styleFrom(
                  backgroundColor: PetugasDrawer.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _memuatRiwayat ? null : _resetFilterTanggal,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: hijau,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_memuatRiwayat)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator(color: hijau)),
          )
        else if (_daftarPenarikan.isEmpty)
          _kartu(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada riwayat penarikan terverifikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          )
        else
          ..._daftarPenarikan.map(_buildItemDaftar),

        if (!_memuatRiwayat && _totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _fieldTanggal({
    required String label,
    required DateTime? tanggal,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          tanggal == null
              ? 'Pilih Tanggal'
              : formatTanggal(_formatTanggalApi(tanggal)),
          style: TextStyle(
            fontSize: 12,
            color: tanggal == null ? Colors.black54 : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _muatDaftarPenarikan(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Halaman $_currentPage dari $_totalPages'),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => _muatDaftarPenarikan(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDaftar(Map<String, dynamic> data) {
    final nominal = _angka(data['nominal']);
    final tanggalVerifikasi = data['tanggal_verifikasi'];

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['nama_nasabah']?.toString() ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hijauMuda,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 13, color: hijau),
                      SizedBox(width: 4),
                      Text(
                        'Terverifikasi',
                        style: TextStyle(
                          color: hijau,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatRupiah(nominal),
              style: const TextStyle(
                color: hijau,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(height: 18),
            _barisDetail(
              'Tanggal Pengajuan',
              formatTanggal(data['tgl_pengajuan']),
            ),
            _barisDetail(
              'Tanggal Verifikasi',
              tanggalVerifikasi == null
                  ? '-'
                  : _formatTanggalWaktu(tanggalVerifikasi),
            ),
            _barisDetail('ID Petugas', data['id_petugas']?.toString() ?? '-'),
          ],
        ),
      ),
    );
  }

  String _formatTanggalWaktu(dynamic tanggal) {
    if (tanggal == null || tanggal.toString().isEmpty) return '-';

    final date = DateTime.tryParse(tanggal.toString());
    if (date == null) return tanggal.toString();

    return '${formatTanggal(date.toIso8601String())}'
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _kartu({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _barisDetail(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              nilai,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

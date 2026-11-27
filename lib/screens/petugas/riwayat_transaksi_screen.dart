import 'package:flutter/material.dart';

import '../../models/setoran_model.dart';
import '../../models/riwayat_item_model.dart';
import '../../services/api_service.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  static const int _pageSize = 20;

  static const Color darkGreen = Color(0xFF0F463D);
  static const Color primaryGreen = Color(0xFF2D765D);
  static const Color background = Color(0xFFF5F8F7);
  static const Color textDark = Color(0xFF153B38);
  static const Color textGrey = Color(0xFF6B7F7B);
  static const Color orange = Color(0xFFD88916);

  String _filter = 'Semua';
  String _searchNama = '';

  DateTime? _tanggalMulai;
  DateTime? _tanggalSampai;

  int _currentPage = 1;

  final TextEditingController _searchController = TextEditingController();

  List<SetoranModel> _setoran = [];
  List<Map<String, dynamic>> _penarikan = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      // Ambil seluruh data setoran tanpa filter bulan dan tahun.
      Future<List<SetoranModel>> ambilSemuaSetoran() async {
        final List<SetoranModel> semua = [];

        int halaman = 1;
        bool masihAda = true;

        while (masihAda) {
          final hasil = await ApiService.getPetugasSetoranPage(
            page: halaman,
            perPage: 20,
          );

          semua.addAll(hasil.items);

          masihAda = hasil.hasMore;
          halaman++;
        }

        return semua;
      }

      // Ambil seluruh data penarikan.
      final hasil = await Future.wait([
        ambilSemuaSetoran(),
        ApiService.getPenarikanPetugas(),
      ]);

      if (!mounted) return;

      setState(() {
        _setoran = hasil[0] as List<SetoranModel>;
        _penarikan = hasil[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      debugPrint('RIWAYAT TRANSAKSI ERROR: $e');
    }
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String formatRupiah(num value) {
    final number = value.round().toString();

    final formatted = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );

    return 'Rp $formatted';
  }

  // ============================================================
  // FORMAT ANGKA
  // ============================================================

  String formatAngka(num value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2).replaceAll('.', ',');
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);

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
    } catch (_) {
      return tanggal;
    }
  }

  String formatTanggalLengkap(DateTime tanggal) {
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  // ============================================================
  // KONVERSI ANGKA
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // FILTER NAMA DAN TANGGAL
  // ============================================================

  bool _sesuaiFilterTanggal(DateTime tanggal) {
    final tanggalTransaksi = DateTime(tanggal.year, tanggal.month, tanggal.day);

    if (_tanggalMulai != null) {
      final mulai = DateTime(
        _tanggalMulai!.year,
        _tanggalMulai!.month,
        _tanggalMulai!.day,
      );

      if (tanggalTransaksi.isBefore(mulai)) {
        return false;
      }
    }

    if (_tanggalSampai != null) {
      final sampai = DateTime(
        _tanggalSampai!.year,
        _tanggalSampai!.month,
        _tanggalSampai!.day,
      );

      if (tanggalTransaksi.isAfter(sampai)) {
        return false;
      }
    }

    return true;
  }

  bool _sesuaiFilterNama(String nama) {
    if (_searchNama.trim().isEmpty) return true;

    return nama.toLowerCase().contains(_searchNama.trim().toLowerCase());
  }

  // ============================================================
  // GABUNGKAN RIWAYAT TRANSAKSI
  // ============================================================

  List<RiwayatItem> _getRiwayat() {
    final List<RiwayatItem> data = [];

    // ------------------------------------------------------------
    // SETORAN
    // ------------------------------------------------------------

    if (_filter == 'Semua' || _filter == 'Setoran') {
      for (final item in _setoran) {
        final tanggal = DateTime.tryParse(item.tanggal);

        if (tanggal == null) continue;

        if (!_sesuaiFilterTanggal(tanggal)) continue;
        if (!_sesuaiFilterNama(item.namaNasabah)) continue;

        data.add(
          RiwayatItem(
            namaNasabah: item.namaNasabah,
            jenis: 'Setoran',
            nominal: item.totalNilai,
            tanggal: tanggal,
            icon: Icons.recycling_rounded,
            warna: primaryGreen,
            status: item.status,
            setoran: item,
          ),
        );
      }
    }

    // ------------------------------------------------------------
    // PENARIKAN
    // ------------------------------------------------------------

    if (_filter == 'Semua' || _filter == 'Penarikan') {
      for (final item in _penarikan) {
        final tanggalString = item['tgl_pengajuan']?.toString() ?? '';

        final tanggal = DateTime.tryParse(tanggalString);

        if (tanggal == null) continue;

        final nama = item['nama_nasabah']?.toString() ?? '-';

        if (!_sesuaiFilterTanggal(tanggal)) continue;
        if (!_sesuaiFilterNama(nama)) continue;

        data.add(
          RiwayatItem(
            namaNasabah: nama,
            jenis: 'Penarikan',
            nominal: _toDouble(item['nominal']),
            tanggal: tanggal,
            icon: Icons.account_balance_wallet_outlined,
            warna: orange,
            status: item['status']?.toString(),
          ),
        );
      }
    }

    // Transaksi terbaru ditampilkan paling atas.
    data.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return data;
  }

  List<RiwayatItem> _getVisibleRiwayat(List<RiwayatItem> data) {
    final start = (_currentPage - 1) * _pageSize;

    if (start >= data.length) return [];

    final end = (start + _pageSize).clamp(0, data.length);

    return data.sublist(start, end);
  }

  int _totalPages(List<RiwayatItem> data) {
    return (data.length / _pageSize).ceil().clamp(1, 999999);
  }

  // ============================================================
  // PILIH TANGGAL
  // ============================================================

  Future<void> _pilihTanggalMulai() async {
    final sekarang = DateTime.now();

    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalMulai ?? _tanggalSampai ?? sekarang,
      firstDate: DateTime(2020),
      lastDate: sekarang,
      helpText: 'Pilih Tanggal Mulai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hasil == null || !mounted) return;

    setState(() {
      _tanggalMulai = hasil;
      _currentPage = 1;
    });
  }

  Future<void> _pilihTanggalSampai() async {
    final sekarang = DateTime.now();

    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalSampai ?? _tanggalMulai ?? sekarang,
      firstDate: DateTime(2020),
      lastDate: sekarang,
      helpText: 'Pilih Tanggal Sampai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hasil == null || !mounted) return;

    setState(() {
      _tanggalSampai = hasil;
      _currentPage = 1;
    });
  }

  // ============================================================
  // RESET FILTER
  // ============================================================

  void _resetFilter() {
    setState(() {
      _searchNama = '';
      _searchController.clear();

      _tanggalMulai = null;
      _tanggalSampai = null;

      _filter = 'Semua';
      _currentPage = 1;
    });
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final semuaRiwayat = _getRiwayat();
    final riwayat = _getVisibleRiwayat(semuaRiwayat);
    final totalPages = _totalPages(semuaRiwayat);

    return Container(
      color: background,
      child: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: const BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Transaksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Daftar transaksi setoran dan penarikan nasabah',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${semuaRiwayat.length} transaksi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ----------------------------------------------------
            // FILTER PANEL
            // ----------------------------------------------------
            SliverToBoxAdapter(child: _buildFilterPanel()),

            // ----------------------------------------------------
            // FILTER JENIS TRANSAKSI
            // ----------------------------------------------------
            SliverToBoxAdapter(child: _buildFilterJenis()),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ----------------------------------------------------
            // LOADING
            // ----------------------------------------------------
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
              )
            // ----------------------------------------------------
            // ERROR
            // ----------------------------------------------------
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 50,
                        color: textGrey,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal mengambil data riwayat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGrey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // ----------------------------------------------------
            // EMPTY STATE
            // ----------------------------------------------------
            else if (semuaRiwayat.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(
                  _searchNama.isNotEmpty ||
                          _tanggalMulai != null ||
                          _tanggalSampai != null
                      ? 'Tidak ada transaksi yang sesuai dengan filter.'
                      : _filter == 'Setoran'
                      ? 'Belum ada transaksi setoran.'
                      : _filter == 'Penarikan'
                      ? 'Belum ada transaksi penarikan.'
                      : 'Belum ada transaksi.',
                ),
              )
            else if (riwayat.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(
                  _searchNama.isNotEmpty ||
                          _tanggalMulai != null ||
                          _tanggalSampai != null
                      ? 'Tidak ada transaksi yang sesuai dengan filter.'
                      : _filter == 'Setoran'
                      ? 'Belum ada transaksi setoran.'
                      : _filter == 'Penarikan'
                      ? 'Belum ada transaksi penarikan.'
                      : 'Belum ada transaksi.',
                ),
              )
            // ----------------------------------------------------
            // DAFTAR TRANSAKSI
            // ----------------------------------------------------
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _transactionCard(riwayat[index]);
                  }, childCount: riwayat.length),
                ),
              ),

              // --------------------------------------------------
              // PAGINATION
              // --------------------------------------------------
              if (totalPages > 1)
                SliverToBoxAdapter(child: _buildPagination(totalPages)),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: textGrey, fontSize: 13),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER PANEL
  // ============================================================

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFE6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cari Transaksi',
            style: TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // SEARCH NAMA NASABAH
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchNama = value;
                _currentPage = 1;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari nama nasabah...',
              hintStyle: const TextStyle(color: textGrey, fontSize: 12),
              prefixIcon: const Icon(
                Icons.search,
                color: primaryGreen,
                size: 20,
              ),
              suffixIcon: _searchNama.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchNama = '';
                          _currentPage = 1;
                        });
                      },
                      icon: const Icon(Icons.close, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDFE6E3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDFE6E3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryGreen),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // LABEL TANGGAL
          const Text(
            'Filter Tanggal',
            style: TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // TANGGAL MULAI DAN SAMPAI
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'Dari Tanggal',
                  value: _tanggalMulai,
                  onTap: _pilihTanggalMulai,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'Sampai Tanggal',
                  value: _tanggalSampai,
                  onTap: _pilihTanggalSampai,
                ),
              ),
            ],
          ),

          if (_tanggalMulai != null &&
              _tanggalSampai != null &&
              _tanggalMulai!.isAfter(_tanggalSampai!))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tanggal mulai tidak boleh melebihi tanggal sampai.',
                style: TextStyle(color: Color(0xFFB42318), fontSize: 11),
              ),
            ),

          const SizedBox(height: 12),

          // RESET
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetFilter,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Filter', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF9),
          border: Border.all(color: const Color(0xFFDFE6E3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: textGrey, fontSize: 10)),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: primaryGreen,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    value == null
                        ? 'Pilih tanggal'
                        : formatTanggalLengkap(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value == null ? textGrey : textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER JENIS TRANSAKSI
  // ============================================================

  Widget _buildFilterJenis() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          _filterButton('Semua'),
          const SizedBox(width: 8),
          _filterButton('Setoran'),
          const SizedBox(width: 8),
          _filterButton('Penarikan'),
        ],
      ),
    );
  }

  Widget _filterButton(String title) {
    final active = _filter == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filter = title;
            _currentPage = 1;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? primaryGreen : const Color(0xFFDFE6E3),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left, color: primaryGreen),
          ),
          Text(
            'Halaman $_currentPage dari $totalPages',
            style: const TextStyle(color: textDark, fontSize: 12),
          ),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right, color: primaryGreen),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSACTION CARD
  // ============================================================

  Widget _transactionCard(RiwayatItem item) {
    final isSetoran = item.jenis == 'Setoran';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDFE6E3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: isSetoran && item.setoran != null
              ? () => _showDetailSetoran(item.setoran!)
              : null,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.warna.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, color: item.warna, size: 23),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaNasabah,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: item.warna,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.jenis,
                            style: TextStyle(
                              color: item.warna,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: textGrey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formatTanggal(item.tanggal.toIso8601String()),
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isSetoran ? '+' : '-'}${formatRupiah(item.nominal)}',
                      style: TextStyle(
                        color: isSetoran ? primaryGreen : orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (item.status != null && item.status!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      _statusBadge(item.status!),
                    ],

                    if (isSetoran) ...[
                      const SizedBox(height: 5),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textGrey,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET DETAIL SETORAN
  // ============================================================

  void _showDetailSetoran(SetoranModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.60,
          minChildSize: 0.40,
          maxChildSize: 0.90,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // HANDLE
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E1DE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F5ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.recycling_rounded,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detail Setoran',
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Rincian jenis sampah nasabah',
                                style: TextStyle(color: textGrey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: textGrey),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // INFORMASI NASABAH
                        _detailInfo('Nama Nasabah', item.namaNasabah),

                        const SizedBox(height: 12),

                        _detailInfo(
                          'Tanggal Setoran',
                          formatTanggal(item.tanggal),
                        ),

                        const SizedBox(height: 12),

                        _detailInfo('Status', item.status),

                        const SizedBox(height: 20),

                        const Text(
                          'Rincian Sampah',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (item.rincian.isNotEmpty)
                          ...item.rincian.map(
                            (detail) => _detailSampahCard(detail),
                          )
                        else
                          _detailSampahFallback(item),

                        const SizedBox(height: 16),

                        // TOTAL
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F5ED),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Berat',
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${formatAngka(item.totalBerat)} gram',
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              const Divider(color: Color(0xFFD0E7D9)),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Nominal',
                                    style: TextStyle(
                                      color: textDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(item.totalNilai),
                                    style: const TextStyle(
                                      color: primaryGreen,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _detailInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(color: textGrey, fontSize: 12),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailSampahCard(DetailSetoranModel detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.namaSampah,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Berat',
                style: TextStyle(color: textGrey, fontSize: 11),
              ),
              Text(
                '${formatAngka(detail.totalBerat)} gram',
                style: const TextStyle(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga per kg',
                style: TextStyle(color: textGrey, fontSize: 11),
              ),
              Text(
                formatRupiah(detail.hargaPerKg),
                style: const TextStyle(color: textDark, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: textGrey, fontSize: 11),
              ),
              Text(
                formatRupiah(detail.totalNilai),
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fallback apabila API tidak mengirim detail_setoran.
  Widget _detailSampahFallback(SetoranModel item) {
    return _detailSampahCard(
      DetailSetoranModel(
        idJenisSampah: item.idJenisSampah ?? 0,
        namaSampah: item.namaSampah,
        totalBerat: item.totalBerat,
        hargaPerKg: item.hargaPerKg,
        totalNilai: item.totalNilai,
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final normalized = status.trim().toLowerCase();

    String label;
    Color warna;

    switch (normalized) {
      case 'pending':
      case 'menunggu':
      case 'menunggu verfikasi':
      case 'menunggu verifikasi':
        label = 'Menunggu';
        warna = orange;
        break;

      case 'approved':
      case 'disetujui':
        label = 'Disetujui';
        warna = primaryGreen;
        break;

      case 'selesai':
      case 'completed':
        label = 'Selesai';
        warna = darkGreen;
        break;

      case 'ditolak':
      case 'rejected':
        label = 'Ditolak';
        warna = const Color(0xFFB42318);
        break;

      case 'dibatalkan':
      case 'cancelled':
      case 'canceled':
        label = 'Dibatalkan';
        warna = textGrey;
        break;

      default:
        label = status;
        warna = textGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: warna,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

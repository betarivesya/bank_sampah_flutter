import 'package:flutter/material.dart';

import '../../models/setoran_model.dart';
import '../../services/api_service.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  static const int _pageSize = 20;
  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color lightGreen = Color(0xFFE8F5F1);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7B8A89);

  String _filter = 'Semua';
  int _currentPage = 1;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<DateTime> get _monthOptions {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    return List.generate(12, (index) => DateTime(now.year, now.month - index));
  }

  List<SetoranModel> _setoran = [];
  List<Map<String, dynamic>> _penarikan = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA SETORAN DAN PENARIKAN
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasil = await Future.wait([
        ApiService.getSetoran(
          bulan: _selectedMonth.month,
          tahun: _selectedMonth.year,
        ),
        ApiService.getPenarikanPetugas(
          bulan: _selectedMonth.month,
          tahun: _selectedMonth.year,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _setoran = (hasil[0] as List<SetoranModel>)
            .where(_isSelectedMonth)
            .toList();
        _penarikan = (hasil[1] as List<Map<String, dynamic>>).where((item) {
          final tanggal = DateTime.tryParse(
            item['tgl_pengajuan']?.toString() ?? '',
          );
          return tanggal == null ||
              (tanggal.year == _selectedMonth.year &&
                  tanggal.month == _selectedMonth.month);
        }).toList();
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

  // ============================================================
  // KONVERSI NILAI ANGKA
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // FILTER DAN GABUNGKAN RIWAYAT
  // ============================================================

  List<_RiwayatItem> _getRiwayat() {
    final List<_RiwayatItem> data = [];

    // ------------------------------------------------------------
    // RIWAYAT SETORAN
    // ------------------------------------------------------------

    if (_filter == 'Semua' || _filter == 'Setoran') {
      for (final item in _setoran) {
        data.add(
          _RiwayatItem(
            namaNasabah: item.namaNasabah,
            jenis: 'Setoran',
            detail: '${item.namaSampah} • ${item.totalBerat} kg',
            nominal: item.totalNilai,
            tanggal:
                DateTime.tryParse(item.tanggal) ??
                DateTime.fromMillisecondsSinceEpoch(0),
            icon: Icons.recycling_rounded,
            warna: primaryGreen,
            status: item.status,
          ),
        );
      }
    }

    // ------------------------------------------------------------
    // RIWAYAT PENARIKAN
    // ------------------------------------------------------------

    if (_filter == 'Semua' || _filter == 'Penarikan') {
      for (final item in _penarikan) {
        final tanggalString = item['tgl_pengajuan']?.toString() ?? '';

        data.add(
          _RiwayatItem(
            namaNasabah: item['nama_nasabah']?.toString() ?? '-',
            jenis: 'Penarikan',
            detail: 'Penarikan saldo',
            nominal: _toDouble(item['nominal']),
            tanggal:
                DateTime.tryParse(tanggalString) ??
                DateTime.fromMillisecondsSinceEpoch(0),
            icon: Icons.account_balance_wallet_outlined,
            warna: Colors.orange.shade700,
            status: item['status']?.toString(),
          ),
        );
      }
    }

    // Urutkan dari transaksi terbaru.
    data.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return data;
  }

  List<_RiwayatItem> _getVisibleRiwayat(List<_RiwayatItem> data) {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= data.length) return [];
    final end = (start + _pageSize).clamp(0, data.length);
    return data.sublist(start, end);
  }

  int _totalPages(List<_RiwayatItem> data) =>
      (data.length / _pageSize).ceil().clamp(1, 999999);

  @override
  Widget build(BuildContext context) {
    final semuaRiwayat = _getRiwayat();

    return Container(
      color: background,
      child: Column(
        children: [
          // ============================================================
          // HEADER
          // ============================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: const BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Lihat seluruh aktivitas transaksi nasabah',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 18),
                _buildMonthSelector(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _filterButton('Semua'),
                    const SizedBox(width: 8),
                    _filterButton('Setoran'),
                    const SizedBox(width: 8),
                    _filterButton('Penarikan'),
                  ],
                ),
              ],
            ),
          ),

          // ============================================================
          // CONTENT
          // ============================================================
          Expanded(child: _buildContent(semuaRiwayat)),
        ],
      ),
    );
  }

  bool _isSelectedMonth(SetoranModel item) {
    final tanggal = DateTime.tryParse(item.tanggal);
    return tanggal == null ||
        (tanggal.year == _selectedMonth.year &&
            tanggal.month == _selectedMonth.month);
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          isExpanded: true,
          value: _selectedMonth,
          dropdownColor: darkGreen,
          icon: const Icon(Icons.calendar_month, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: _monthOptions.map((month) {
            return DropdownMenuItem(
              value: month,
              child: Text('${_namaBulan(month.month)} ${month.year}'),
            );
          }).toList(),
          onChanged: (month) {
            if (month == null) return;
            setState(() => _selectedMonth = month);
            _loadData();
          },
        ),
      ),
    );
  }

  String _namaBulan(int bulan) {
    const nama = [
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
    return nama[bulan - 1];
  }

  // ============================================================
  // BUILD CONTENT
  // ============================================================

  Widget _buildContent(List<_RiwayatItem> semuaRiwayat) {
    final riwayat = _getVisibleRiwayat(semuaRiwayat);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey),
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
      );
    }

    if (riwayat.isEmpty) {
      String message;

      switch (_filter) {
        case 'Setoran':
          message = 'Belum ada transaksi setoran.';
          break;
        case 'Penarikan':
          message = 'Belum ada transaksi penarikan.';
          break;
        default:
          message = 'Belum ada transaksi.';
      }

      return RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Center(
                child: Text(
                  message,
                  style: const TextStyle(color: textGrey, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: riwayat.length + (_totalPages(semuaRiwayat) > 1 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == riwayat.length) {
            return _buildPagination(_totalPages(semuaRiwayat));
          }
          return _transactionCard(riwayat[index]);
        },
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

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
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? darkGreen : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            'Halaman $_currentPage dari $totalPages',
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSACTION CARD
  // ============================================================

  Widget _transactionCard(_RiwayatItem item) {
    final isSetoran = item.jenis == 'Setoran';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.warna.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.warna, size: 24),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(color: textGrey, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: textGrey,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        formatTanggal(item.tanggal.toIso8601String()),
                        style: const TextStyle(color: textGrey, fontSize: 11),
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
                  color: isSetoran ? primaryGreen : Colors.orange.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.status != null && item.status!.isNotEmpty) ...[
                const SizedBox(height: 5),
                _statusBadge(item.status!),
              ],
            ],
          ),
        ],
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
        label = 'Menunggu Verfikasi';
        warna = Colors.orange;
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
        warna = Colors.redAccent;
        break;

      case 'dibatalkan':
      case 'cancelled':
      case 'canceled':
        label = 'Dibatalkan';
        warna = Colors.blueGrey;
        break;

      default:
        label = status;
        warna = Colors.blueGrey;
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

// ============================================================
// RIWAYAT ITEM
// ============================================================

class _RiwayatItem {
  final String namaNasabah;
  final String jenis;
  final String detail;
  final double nominal;
  final DateTime tanggal;
  final IconData icon;
  final Color warna;
  final String? status;

  _RiwayatItem({
    required this.namaNasabah,
    required this.jenis,
    required this.detail,
    required this.nominal,
    required this.tanggal,
    required this.icon,
    required this.warna,
    this.status,
  });
}

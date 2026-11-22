import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../models/setoran_model.dart';
import '../../services/api_service.dart';
import 'tambah_setoran_screen.dart';

class SetoranScreen extends StatefulWidget {
  final int idPetugas;

  const SetoranScreen({super.key, required this.idPetugas});

  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> {
  static const int _pageSize = 20;
  List<SetoranModel> _setoran = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadSetoran();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadSetoran({int page = 1}) async {
    _currentPage = page;
    setState(() {
      _loading = true;
    });

    try {
      final result = await ApiService.getPetugasSetoranPage(
        bulan: _selectedMonth.month,
        tahun: _selectedMonth.year,
        page: page,
        perPage: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _setoran = result.items;
        _totalPages = result.lastPage;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data setoran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String _formatTanggal(String tanggal) {
    if (tanggal.isEmpty) return '-';

    try {
      final date = DateTime.parse(tanggal);

      return tanggalIndonesia(date);
    } catch (_) {
      return tanggal;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: RefreshIndicator(
        onRefresh: () => _loadSetoran(page: 1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),

            _buildMonthSelector(),
            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 50),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF075B4F)),
                ),
              )
            else if (_setoran.isEmpty)
              _buildEmptyContent()
            else ...[
              ..._setoran.map(
                (item) => _SetoranCard(
                  setoran: item,
                  tanggal: _formatTanggal(item.tanggal),
                ),
              ),
              if (_totalPages > 1) _buildPagination(),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),

      // ============================================================
      // TAMBAH SETORAN
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF075B4F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Setoran Baru'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TambahSetoranScreen(idPetugas: widget.idPetugas),
            ),
          );

          if (result == true) {
            _loadSetoran(page: 1);
          }
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Setor Sampah',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Kelola dan catat setoran sampah nasabah',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF075B4F),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_setoran.length} Setoran',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF075B4F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return InkWell(
      onTap: _pilihBulanSetoran,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4EAE7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_namaBulan(_selectedMonth.month)} '
              '${_selectedMonth.year}',
              style: const TextStyle(
                color: Color(0xFF075B4F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF075B4F),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pilihBulanSetoran() async {
    int bulanDipilh = _selectedMonth.month;
    int tahunDipilih = _selectedMonth.year;

    final sekarang = DateTime.now();

    final hasil = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(18),
              ),
              title: const Text(
                'Pilih Bulan dan Tahun',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075B4F),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: bulanDipilh,
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(_namaBulan(index + 1)),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          bulanDipilh = value;

                          if (tahunDipilih == sekarang.year &&
                              bulanDipilh == sekarang.month) {
                            bulanDipilh = sekarang.month;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int>(
                    value: tahunDipilih,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(sekarang.year - 2020 + 1, (index) {
                      final tahun = sekarang.year - index;

                      return DropdownMenuItem(
                        value: tahun,
                        child: Text('$tahun'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          tahunDipilih = value;

                          if (tahunDipilih == sekarang.year &&
                              bulanDipilh == sekarang.month) {
                            bulanDipilh = sekarang.month;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075B4F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      DateTime(tahunDipilih, bulanDipilh),
                    );
                  },
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
      },
    );

    if (hasil == null || !mounted) return;

    if (hasil.year == _selectedMonth.year &&
        hasil.month == _selectedMonth.month) {
      return;
    }

    setState(() {
      _selectedMonth = hasil;
      _currentPage = 1;
    });

    await _loadSetoran(page: 1);
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

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _loadSetoran(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Halaman $_currentPage dari $_totalPages'),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => _loadSetoran(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyContent() {
    return const Padding(
      padding: EdgeInsetsGeometry.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 70, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada data setoran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada riwayat setoran pada bulan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARD SETORAN
// ============================================================

class _SetoranCard extends StatelessWidget {
  final SetoranModel setoran;
  final String tanggal;

  const _SetoranCard({required this.setoran, required this.tanggal});

  void _bukaRincian(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RincianSetoranSheet(setoran: setoran, tanggal: tanggal);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAE7)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _bukaRincian(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF075B4F)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            setoran.namaNasabah,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                tanggal,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: setoran.status),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, color: Color(0xFFEAEFEC)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 17,
                      color: Color(0xFF075B4F),
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'Lihat rincian setoran',
                        style: TextStyle(
                          color: Color(0xFF075B4F),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF075B4F),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM SHEET RINCIAN SETORAN
// ============================================================

class _RincianSetoranSheet extends StatelessWidget {
  final SetoranModel setoran;
  final String tanggal;

  const _RincianSetoranSheet({required this.setoran, required this.tanggal});

  String _formatBerat(double berat) {
    final angka = berat.toStringAsFixed(0);
    return angka.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final rincian = setoran.rincian;

    // Hitung dari rincian agar total sesuai dengan daftar item.
    final totalBerat = rincian.fold<double>(
      0,
      (total, item) => total + item.totalBerat,
    );

    final totalNilai = rincian.fold<double>(
      0,
      (total, item) => total + item.totalNilai,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HANDLE DAN HEADER
            Padding(
              padding: const EdgeInsetsGeometry.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF075B4F),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Rincian Setoran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          setoran.namaNasabah,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tanggal,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(status: setoran.status),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ISI RINCIAN
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daftar Jenis Sampah',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (rincian.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Rincian jenis sampah belum tersedia.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...rincian.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE4EAE7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5F1),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(
                                      Icons.recycling,
                                      size: 19,
                                      color: Color(0xFF075B4F),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.namaSampah,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_formatBerat(item.totalBerat)} gram',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF075B4F),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 13),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              _RincianBaris(
                                label: 'Harga per kg',
                                value: rupiah(item.hargaPerKg),
                              ),
                              const SizedBox(height: 8),
                              _RincianBaris(
                                label: 'Subtotal',
                                value: rupiah(item.totalNilai),
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 5),

                    // RINGKASAN TOTAL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Ringkasan Setoran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF075B4F),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _RincianBaris(
                            label: 'Total Berat',
                            value: rincian.isNotEmpty
                                ? '${_formatBerat(totalBerat)} gram'
                                : '${_formatBerat(setoran.totalBerat)} gram',
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFD0E5DC)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total Nilai',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF172033),
                                  ),
                                ),
                              ),
                              Text(
                                rupiah(
                                  rincian.isNotEmpty
                                      ? totalNilai
                                      : setoran.totalNilai,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF075B4F),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BARIS RINCIAN
// ============================================================

class _RincianBaris extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _RincianBaris({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF172033),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATUS
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  String get _statusTampilan {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'selesai':
        return 'Selesai';

      case 'pending':
        return 'Menunggu';

      case 'rejected':
        return 'Ditolak';

      case 'cancelled':
      case 'canceled':
        return 'Dibatalkan';

      default:
        return status.isEmpty ? '-' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusNormal = status.trim().toLowerCase();

    Color warnaLatar;
    Color warnaTeks;

    switch (statusNormal) {
      case 'approved':
      case 'selesai':
        warnaLatar = const Color(0xFFE8F5F1);
        warnaTeks = const Color(0xFF075B4F);
        break;

      case 'pending':
        warnaLatar = const Color(0xFFFFF4DB);
        warnaTeks = const Color(0xFF9A6700);
        break;

      case 'rejected':
      case 'cancelled':
      case 'canceled':
        warnaLatar = const Color(0xFFFDECEC);
        warnaTeks = const Color(0xFFC62828);
        break;

      default:
        warnaLatar = const Color(0xFFF0F0F0);
        warnaTeks = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusTampilan,
        style: TextStyle(
          color: warnaTeks,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// INFO ITEM
// ============================================================

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2E8B72)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

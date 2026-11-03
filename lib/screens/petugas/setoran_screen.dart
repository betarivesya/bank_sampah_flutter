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

  List<DateTime> get _monthOptions {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    return List.generate(12, (index) => DateTime(now.year, now.month - index));
  }

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
        onRefresh: _loadSetoran,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF075B4F)),
              )
            : _setoran.isEmpty
            ? _buildEmpty()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildMonthSelector(),
                  const SizedBox(height: 20),
                  ..._setoran.map(
                    (item) => _SetoranCard(
                      setoran: item,
                      tanggal: _formatTanggal(item.tanggal),
                    ),
                  ),
                  if (_totalPages > 1) _buildPagination(),
                  const SizedBox(height: 80),
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
            _loadSetoran();
          }
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.recycling,
              color: Color(0xFF075B4F),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Setoran Sampah',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_setoran.length} transaksi setoran',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAE7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          isExpanded: true,
          value: _selectedMonth,
          icon: const Icon(Icons.calendar_month, color: Color(0xFF075B4F)),
          items: _monthOptions.map((month) {
            return DropdownMenuItem(
              value: month,
              child: Text('Setoran ${_namaBulan(month.month)} ${month.year}'),
            );
          }).toList(),
          onChanged: (month) {
            if (month == null) return;
            setState(() => _selectedMonth = month);
            _loadSetoran();
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

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.inbox_outlined, size: 70, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Belum ada data setoran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Tambahkan setoran baru untuk nasabah.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAE7)),
      ),
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
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tanggal,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: setoran.status),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'Jenis Sampah',
                  value: setoran.namaSampah,
                  icon: Icons.recycling,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'Berat',
                  value: '${setoran.totalBerat} kg',
                  icon: Icons.scale,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'Harga/kg',
                  value: rupiah(setoran.hargaPerKg),
                  icon: Icons.sell_outlined,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'Total',
                  value: rupiah(setoran.totalNilai),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
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

// ============================================================
// STATUS
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF075B4F),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

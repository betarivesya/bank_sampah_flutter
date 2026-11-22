import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/api_service.dart';
import 'tambah_transaksi_keuangan_screen.dart';

class ManajemenKeuanganScreen extends StatefulWidget {
  const ManajemenKeuanganScreen({super.key});

  @override
  State<ManajemenKeuanganScreen> createState() =>
      _ManajemenKeuanganScreenState();
}

class _ManajemenKeuanganScreenState extends State<ManajemenKeuanganScreen> {
  static const Color darkGreen = Color(0xFF0F463D);
  static const Color background = Color(0xFFF4F7FB);

  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _jenisSampah = [];
  bool _saldoAwalSudahAda = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _filterJenis;
  String? _filterKategori;
  DateTime? _tanggalDari;
  DateTime? _tanggalSampai;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalTransactions = 0;

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

  Future<void> _loadData({int page = 1, bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final filters = <String, String>{'page': page.toString(), 'per_page': '10'};
    final query = _searchController.text.trim();
    final filterJenis = _filterJenis;
    final filterKategori = _filterKategori;
    final tanggalDari = _tanggalDari;
    final tanggalSampai = _tanggalSampai;

    if (query.isNotEmpty) filters['q'] = query;
    if (filterJenis != null) filters['jenis_transaksi'] = filterJenis;
    if (filterKategori != null) filters['kategori'] = filterKategori;
    if (tanggalDari != null) {
      filters['tanggal_dari'] = _dateQuery(tanggalDari);
    }
    if (tanggalSampai != null) {
      filters['tanggal_sampai'] = _dateQuery(tanggalSampai);
    }

    try {
      final response = await ApiService.getAdminKeuangan(filters: filters);
      final data = response['data'];
      final meta = response['meta'];

      if (!mounted) return;

      setState(() {
        _transactions = data is List
            ? data
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        _summary = response['summary'] is Map
            ? Map<String, dynamic>.from(response['summary'])
            : {};
        _jenisSampah = response['jenis_sampah'] is List
            ? (response['jenis_sampah'] as List)
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        _saldoAwalSudahAda = response['saldo_awal_sudah_ada'] == true;
        _currentPage =
            int.tryParse(
              meta is Map ? meta['current_page']?.toString() ?? '' : '',
            ) ??
            1;
        _lastPage =
            int.tryParse(
              meta is Map ? meta['last_page']?.toString() ?? '' : '',
            ) ??
            1;
        _totalTransactions =
            int.tryParse(meta is Map ? meta['total']?.toString() ?? '' : '') ??
            _transactions.length;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _applyFilters() => _loadData(page: 1);

  Future<void> _pickDate({required bool startDate}) async {
    final selectedDate = startDate ? _tanggalDari : _tanggalSampai;
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    setState(() {
      if (startDate) {
        _tanggalDari = date;
        if (_tanggalSampai != null && date.isAfter(_tanggalSampai!)) {
          _tanggalSampai = null;
        }
      } else {
        _tanggalSampai = date;
      }
    });
  }

  Future<void> _openNewTransaction() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahTransaksiKeuanganScreen(
          jenisSampah: _jenisSampah,
          saldoAwalSudahAda: _saldoAwalSudahAda,
        ),
      ),
    );

    if (saved == true) {
      await _loadData(page: 1);
    }
  }

  Future<void> _openProof(String proofUrl) async {
    final proofUri = _resolveProofUrl(proofUrl);
    final path = proofUri.path.toLowerCase();

    if (path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png')) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image.network(
              proofUri.toString(),
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Bukti gambar tidak dapat dimuat.'),
              ),
            ),
          ),
        ),
      );
      return;
    }

    try {
      final response = await http.get(proofUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Bukti transaksi tidak dapat diunduh.');
      }

      final directory = await getTemporaryDirectory();
      final fileName = proofUri.pathSegments.isEmpty
          ? 'bukti-transaksi.pdf'
          : proofUri.pathSegments.last;
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done && mounted) {
        _showMessage('Tidak ada aplikasi untuk membuka bukti transaksi ini.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Uri _resolveProofUrl(String url) {
    final uri = Uri.parse(url);
    final apiUri = Uri.parse(ApiService.baseUrl);

    if (uri.hasScheme) {
      if (uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1') {
        return uri.replace(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: apiUri.port,
        );
      }

      return uri;
    }

    return apiUri.resolve(uri.toString());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _dateQuery(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}';
  }

  String _formatRupiah(dynamic value) {
    final amount = num.tryParse(value?.toString() ?? '')?.round() ?? 0;
    final digits = amount.abs().toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return 'Rp${amount < 0 ? '-' : ''}$formatted';
  }

  Widget _buildSummaryCard({
    required String title,
    required dynamic amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF71847F)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _formatRupiah(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cari dan filter transaksi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applyFilters(),
              decoration: InputDecoration(
                labelText: 'Kode, keterangan, atau pencatat',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const ValueKey('filter-jenis-transaksi'),
              initialValue: _filterJenis,
              decoration: InputDecoration(
                labelText: 'Jenis transaksi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua jenis')),
                DropdownMenuItem(value: 'pemasukan', child: Text('Pemasukan')),
                DropdownMenuItem(
                  value: 'pengeluaran',
                  child: Text('Pengeluaran'),
                ),
              ],
              onChanged: (value) => setState(() => _filterJenis = value),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const ValueKey('filter-kategori-transaksi'),
              initialValue: _filterKategori,
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua kategori')),
                DropdownMenuItem(
                  value: 'saldo_awal',
                  child: Text('Saldo awal'),
                ),
                DropdownMenuItem(
                  value: 'tambahan_modal',
                  child: Text('Tambahan modal'),
                ),
                DropdownMenuItem(
                  value: 'penjualan_induk',
                  child: Text('Penjualan ke induk'),
                ),
                DropdownMenuItem(
                  value: 'operasional',
                  child: Text('Operasional'),
                ),
                DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
              ],
              onChanged: (value) => setState(() => _filterKategori = value),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(startDate: true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _tanggalDari == null
                          ? 'Dari tanggal'
                          : _formatDate(_dateQuery(_tanggalDari!)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(startDate: false),
                    icon: const Icon(Icons.event, size: 16),
                    label: Text(
                      _tanggalSampai == null
                          ? 'Sampai tanggal'
                          : _formatDate(_dateQuery(_tanggalSampai!)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Terapkan'),
                    style: FilledButton.styleFrom(backgroundColor: darkGreen),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _filterJenis = null;
                      _filterKategori = null;
                      _tanggalDari = null;
                      _tanggalSampai = null;
                    });
                    _loadData(page: 1);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isIncome = transaction['jenis_transaksi'] == 'pemasukan';
    final color = isIncome ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final detailPenjualan = transaction['detail_penjualan'] is List
        ? (transaction['detail_penjualan'] as List)
              .whereType<Map>()
              .map((detail) => Map<String, dynamic>.from(detail))
              .toList()
        : <Map<String, dynamic>>[];
    final proofUrl = transaction['bukti_url']?.toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['kode_transaksi']?.toString() ?? '-',
                        style: const TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(transaction['tanggal_transaksi'])} · '
                        '${transaction['pencatat'] ?? 'Admin'}',
                        style: const TextStyle(
                          color: Color(0xFF71847F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncome ? '+' : '-'} ${_formatRupiah(transaction['nominal'])}',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _tag(
                  isIncome ? 'Pemasukan' : 'Pengeluaran',
                  color.withValues(alpha: 0.1),
                  color,
                ),
                _tag(
                  _categoryLabel(transaction['kategori']?.toString() ?? ''),
                  const Color(0xFFE6F2EE),
                  darkGreen,
                ),
              ],
            ),
            if ((transaction['keterangan']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(transaction['keterangan'].toString()),
            ],
            if (detailPenjualan.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...detailPenjualan.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${detail['nama_sampah'] ?? 'Sampah'} · '
                    '${detail['berat_kg']} kg · '
                    '${_formatRupiah(detail['subtotal'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF71847F),
                    ),
                  ),
                ),
              ),
            ],
            if (proofUrl != null && proofUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openProof(proofUrl),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Lihat bukti transaksi'),
                  style: TextButton.styleFrom(foregroundColor: darkGreen),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color backgroundColor, Color foregroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'saldo_awal' => 'Saldo awal',
      'tambahan_modal' => 'Tambahan modal',
      'penjualan_induk' => 'Penjualan ke induk',
      'operasional' => 'Operasional',
      _ => 'Lainnya',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _summary.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }

    if (_errorMessage != null && _summary.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: darkGreen),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadData,
                style: FilledButton.styleFrom(backgroundColor: darkGreen),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: background,
      child: RefreshIndicator(
        color: darkGreen,
        onRefresh: () => _loadData(showLoading: false),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manajemen Keuangan',
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pencatatan kas Bank Sampah Griya Ayu',
                        style: TextStyle(
                          color: Color(0xFF71847F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Catat transaksi',
                  onPressed: _openNewTransaction,
                  style: IconButton.styleFrom(backgroundColor: darkGreen),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.65,
              children: [
                _buildSummaryCard(
                  title: 'Kas tunai bank sampah',
                  amount: _summary['kas_bank_sampah'],
                  icon: Icons.account_balance_wallet_outlined,
                  color: darkGreen,
                ),
                _buildSummaryCard(
                  title: 'Total saldo nasabah',
                  amount: _summary['total_saldo_nasabah'],
                  icon: Icons.people_outline,
                  color: const Color(0xFF0F463D),
                ),
                _buildSummaryCard(
                  title: 'Pemasukan bulan ini',
                  amount: _summary['pemasukan_bulan_ini'],
                  icon: Icons.south_west,
                  color: const Color(0xFF15803D),
                ),
                _buildSummaryCard(
                  title: 'Pengeluaran bulan ini',
                  amount: _summary['pengeluaran_bulan_ini'],
                  icon: Icons.north_east,
                  color: const Color(0xFFB91C1C),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat transaksi',
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$_totalTransactions transaksi',
                  style: const TextStyle(
                    color: Color(0xFF71847F),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: darkGreen),
                ),
              )
            else if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
              )
            else if (_transactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Belum ada transaksi keuangan.')),
                ),
              )
            else
              ..._transactions.map(_buildTransactionCard),
            if (_lastPage > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Halaman sebelumnya',
                    onPressed: _currentPage > 1
                        ? () => _loadData(page: _currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Halaman $_currentPage dari $_lastPage'),
                  IconButton(
                    tooltip: 'Halaman berikutnya',
                    onPressed: _currentPage < _lastPage
                        ? () => _loadData(page: _currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  static const Color _green = Color(0xFF2E7D32);
  static const Color _background = Color(0xFFF7F8FA);

  List<Map<String, dynamic>> _notifikasi = [];
  bool _loading = true;
  bool _menandaiSemua = false;
  String? _error;

  int get _jumlahBelumDibaca {
    return _notifikasi.where((item) => !_sudahDibaca(item)).length;
  }

  @override
  void initState() {
    super.initState();
    _muatNotifikasi();
  }

  // Memuat notifikasi admin.
  // TODO: Sambungkan ke endpoint API khusus admin.
  Future<void> _muatNotifikasi() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // API notifikasi admin belum disambungkan.
      // Jangan menggunakan API notifikasi nasabah di sini.
      throw Exception('API notifikasi admin belum dihubungkan.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _sudahDibaca(Map<String, dynamic> item) {
    final nilai = item['dibaca'];

    return nilai == true ||
        nilai.toString() == '1' ||
        nilai.toString().toLowerCase() == 'true';
  }

  // Menandai satu notifikasi sebagai sudah dibaca.
  // TODO: Sambungkan ke endpoint API khusus admin.
  Future<void> _tandaiDibaca(Map<String, dynamic> item) async {
    if (_sudahDibaca(item)) return;

    final id = item['id_notifikasi'] ?? item['id'];

    if (id == null) {
      _pesan('ID notifikasi tidak valid.');
      return;
    }

    _pesan('API untuk menandai notifikasi admin belum dihubungkan.');
  }

  // Menandai seluruh notifikasi sebagai sudah dibaca.
  // TODO: Sambungkan ke endpoint API khusus admin.
  Future<void> _tandaiSemuaDibaca() async {
    if (_jumlahBelumDibaca == 0 || _menandaiSemua) return;

    _pesan('API untuk menandai semua notifikasi admin belum dihubungkan.');
  }

  void _pesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  IconData _ikon(String? tipe) {
    switch ((tipe ?? '').toLowerCase()) {
      case 'saldo':
      case 'penarikan':
        return Icons.account_balance_wallet_outlined;
      case 'setoran':
        return Icons.recycling_outlined;
      case 'pengguna':
        return Icons.person_outline;
      case 'laporan':
        return Icons.assignment_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _warna(String? tipe) {
    switch ((tipe ?? '').toLowerCase()) {
      case 'saldo':
      case 'penarikan':
        return const Color(0xFF2E7D32);
      case 'setoran':
        return const Color(0xFF43A047);
      case 'pengguna':
        return const Color(0xFF1976D2);
      case 'laporan':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF1976D2);
    }
  }

  String _formatWaktu(dynamic nilai) {
    if (nilai == null || nilai.toString().isEmpty) {
      return '-';
    }

    try {
      final tanggal = DateTime.parse(nilai.toString()).toLocal();
      final sekarang = DateTime.now();

      final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
      final tanggalNotifikasi = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day,
      );

      final selisih = hariIni.difference(tanggalNotifikasi).inDays;
      final jam = tanggal.hour.toString().padLeft(2, '0');
      final menit = tanggal.minute.toString().padLeft(2, '0');

      if (selisih == 0) {
        return 'Hari ini, $jam:$menit';
      }

      if (selisih == 1) {
        return 'Kemarin, $jam:$menit';
      }

      if (selisih > 1 && selisih < 7) {
        return '$selisih hari lalu';
      }

      final hari = tanggal.day.toString().padLeft(2, '0');
      final bulan = tanggal.month.toString().padLeft(2, '0');

      return '$hari/$bulan/${tanggal.year}';
    } catch (_) {
      return nilai.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_jumlahBelumDibaca > 0)
            TextButton(
              onPressed: _menandaiSemua ? null : _tandaiSemuaDibaca,
              child: _menandaiSemua
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Baca semua',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                    ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _muatNotifikasi,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifikasi.isEmpty) {
      return RefreshIndicator(
        onRefresh: _muatNotifikasi,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Belum ada notifikasi',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muatNotifikasi,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _notifikasi.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _notifikasi[index];
          final tipe = item['tipe']?.toString();
          final warna = _warna(tipe);
          final dibaca = _sudahDibaca(item);

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _tandaiDibaca(item),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dibaca ? Colors.white : const Color(0xFFF0F8F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dibaca
                      ? const Color(0xFFEEEEEE)
                      : const Color(0xFFC8E6C9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: warna.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_ikon(tipe), color: warna, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['judul']?.toString() ?? 'Notifikasi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: dibaca
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (!dibaca) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: const BoxDecoration(
                                  color: _green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item['pesan']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatWaktu(item['created_at']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

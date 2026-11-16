import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/setoran_model.dart';

class NotifikasiPetugas extends StatefulWidget {
  const NotifikasiPetugas({super.key});

  @override
  State<NotifikasiPetugas> createState() => _NotifikasiPetugasState();
}

class _NotifikasiPetugasState extends State<NotifikasiPetugas> {
  static const Color darkGreen = Color(0xFF075B4F);
  static const Color textDark = Color(0xFF172033);

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _aktivitas = [];

  @override
  void initState() {
    super.initState();
    _muatNotifikasi();
  }

  Future<void> _muatNotifikasi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();

      final hasil = await Future.wait([
        ApiService.getPetugasSetoranPage(
          bulan: now.month,
          tahun: now.year,
          page: 1,
          perPage: 5,
        ),
        ApiService.getPetugasPenarikanPage(
          bulan: now.month,
          tahun: now.year,
          page: 1,
          perPage: 5,
        ),
      ]);

      final setoran = hasil[0] as PetugasPage<SetoranModel>;
      final penarikan = hasil[1] as PetugasPage<Map<String, dynamic>>;

      final aktivitasBaru = <Map<String, dynamic>>[];

      for (final item in setoran.items.take(3)) {
        aktivitasBaru.add({
          'judul': 'Aktivitas Setoran',
          'deskripsi': 'Setoran ${item.namaNasabah} - ${item.namaSampah}',
          'jenis': 'setoran',
        });
      }

      for (final item in penarikan.items.take(3)) {
        aktivitasBaru.add({
          'judul': 'Aktivitas Penarikan',
          'deskripsi':
              'Penarikan ${item['nama_nasabah']?.toString() ?? 'nasabah'} - '
              '${item['status']?.toString() ?? 'menunggu'}',
          'jenis': 'penarikan',
        });
      }

      if (!mounted) return;

      setState(() {
        _aktivitas = aktivitasBaru;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal mengambil notifikasi.';
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'Belum Ada Aktivitas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aktivitas setoran dan penarikan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAktivitas() {
    return RefreshIndicator(
      color: darkGreen,
      onRefresh: _muatNotifikasi,
      child: _aktivitas.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: _buildEmptyState(),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _aktivitas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _aktivitas[index];
                final isSetoran = item['jenis'] == 'setoran';

                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: isSetoran
                              ? const Color(0xFFE5F4EC)
                              : const Color(0xFFFFF1E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSetoran
                              ? Icons.recycling_rounded
                              : Icons.account_balance_wallet_outlined,
                          color: isSetoran ? darkGreen : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['judul'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['deskripsi'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Informasi aktivitas setoran dan penarikan terbaru.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: darkGreen),
                  )
                : _errorMessage != null
                ? Center(
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
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _muatNotifikasi,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildAktivitas(),
          ),
        ],
      ),
    );
  }
}

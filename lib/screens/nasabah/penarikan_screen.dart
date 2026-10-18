import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../services/api_service.dart';

class PenarikanScreen extends StatefulWidget {
  final int idNasabah;

  const PenarikanScreen({super.key, required this.idNasabah});

  @override
  State<PenarikanScreen> createState() => _PenarikanScreenState();
}

class _PenarikanScreenState extends State<PenarikanScreen> {
  final TextEditingController nominalController = TextEditingController();

  double saldo = 0;
  double saldoTertahan = 0;
  bool konfirmasiPenarikan = false;
  bool sedangMemuat = true;
  bool sedangMengirim = false;

  List<Map<String, dynamic>> pengajuan = [];

  @override
  void initState() {
    super.initState();
    muatData();
  }

  @override
  void dispose() {
    nominalController.dispose();
    super.dispose();
  }

  String formatRupiah(num nominal) {
    final formatted = nominal
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');

    return 'Rp$formatted';
  }

  String formatTanggal(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    final tanggal = parsed.day.toString().padLeft(2, '0');
    final bulan = parsed.month.toString().padLeft(2, '0');

    return '$tanggal/$bulan/${parsed.year}';
  }

  String statusLabel(dynamic value) {
    final status = (value ?? '').toString().toLowerCase();

    switch (status) {
      case 'pending':
      case 'menunggu':
      case 'menunggu verifikasi':
        return 'Menunggu Verifikasi';

      case 'disetujui':
      case 'approved':
        return 'Disetujui';

      case 'ditolak':
      case 'rejected':
        return 'Ditolak';

      case 'selesai':
      case 'completed':
        return 'Selesai';

      default:
        return status.isEmpty ? 'Tidak diketahui' : value.toString();
    }
  }

  Color _warnaLatarStatus(dynamic value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'pending':
      case 'menunggu':
      case 'menunggu verifikasi':
        return Colors.orange.withValues(alpha: 0.12);

      case 'disetujui':
      case 'approved':
      case 'selesai':
      case "completed":
        return Colors.green.withValues(alpha: 0.12);

      case 'ditolak':
      case 'rejected':
        return Colors.red.withValues(alpha: 0.10);

      case 'dibatalkan':
      case 'cancelled':
      case 'canceled':
        return Colors.grey.withValues(alpha: 0.12);

      default:
        return Colors.blueGrey.withValues(alpha: 0.10);
    }
  }

  Color _warnaTeksStatus(dynamic value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'pending':
      case 'menunggu':
      case 'menunggu verifikasi':
        return Colors.orange.shade800;

      case 'disetujui':
      case 'approved':
      case 'selesai':
      case "completed":
        return Colors.green.shade700;

      case 'ditolak':
      case 'rejected':
        return Colors.red.shade700;

      case 'dibatalkan':
      case 'cancelled':
      case 'canceled':
        return Colors.grey.shade700;

      default:
        return Colors.blueGrey.shade700;
    }
  }

  Future<void> muatData() async {
    if (mounted) {
      setState(() => sedangMemuat = true);
    }

    try {
      final hasil = await Future.wait([
        ApiService.getNasabah(),
        ApiService.getRiwayatPenarikanNasabah(widget.idNasabah),
      ]);

      final daftarNasabah = List<Map<String, dynamic>>.from(hasil[0] as List);

      final daftarPengajuan = List<Map<String, dynamic>>.from(hasil[1] as List);

      final nasabah = daftarNasabah.firstWhere((item) {
        final id =
            item['id_pengguna_nasabah'] ?? item['id_nasabah'] ?? item['id'];

        return id?.toString() == widget.idNasabah.toString();
      }, orElse: () => <String, dynamic>{});

      if (nasabah.isEmpty) {
        throw Exception('Data nasabah tidak ditemukan.');
      }

      final saldoServer =
          double.tryParse((nasabah['saldo'] ?? 0).toString()) ?? 0;

      // Saldo pengajuan pending belum dipotong server.
      final tertahan = daftarPengajuan
          .where((item) => item['status'].toString().toLowerCase() == 'pending')
          .fold<double>(
            0,
            (total, item) =>
                total +
                (double.tryParse((item['nominal'] ?? 0).toString()) ?? 0),
          );

      if (!mounted) return;

      setState(() {
        saldo = saldoServer;
        saldoTertahan = tertahan;
        pengajuan = daftarPengajuan;
        sedangMemuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => sedangMemuat = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data penarikan: $e')),
      );
    }
  }

  Future<void> prosesPenarikan() async {
    if (sedangMengirim) return;

    final teksNominal = nominalController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s+'), '');

    final nominal = int.tryParse(teksNominal);

    if (nominal == null || nominal < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal penarikan adalah Rp1.000.')),
      );
      return;
    }

    final saldoTersedia = saldo - saldoTertahan;

    if (nominal > saldoTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo tersedia hanya ${formatRupiah(saldoTersedia)}.'),
        ),
      );
      return;
    }

    if (!konfirmasiPenarikan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan centang konfirmasi penarikan terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Penarikan'),
        content: Text('Ajukan penarikan sebesar ${formatRupiah(nominal)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Ajukan'),
          ),
        ],
      ),
    );

    if (yakin != true || !mounted) return;

    setState(() => sedangMengirim = true);

    try {
      final hasil = await ApiService.ajukanPenarikan(
        idNasabah: widget.idNasabah,
        nominal: nominal.toDouble(),
      );

      if (!mounted) return;

      if (hasil['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasil['message'] ?? 'Pengajuan penarikan gagal.'),
          ),
        );
        return;
      }

      nominalController.clear();

      setState(() {
        konfirmasiPenarikan = false;
      });

      await muatData();

      if (!mounted) return;

      final data = hasil['data'] as Map<String, dynamic>? ?? {};

      final kode = data['kode_verifikasi'] ?? data['kode_penarikan'] ?? '-';

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Pengajuan Berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 58,
              ),
              const SizedBox(height: 14),
              const Text(
                'Pengajuan penarikan berhasil dibuat. '
                'Tunjukkan kode verifikasi kepada petugas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Kode Verifikasi'),
                    const SizedBox(height: 6),
                    SelectableText(
                      kode.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(formatRupiah(nominal)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengajukan penarikan: $e')));
    } finally {
      if (mounted) {
        setState(() => sedangMengirim = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldoTersedia = (saldo - saldoTertahan).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pengajuan Penarikan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: sedangMemuat ? null : muatData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: sedangMemuat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: muatData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ajukan Penarikan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Masukkan nominal saldo yang ingin Anda tarik.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saldo Saat Ini'),
                              const SizedBox(height: 5),
                              Text(
                                formatRupiah(saldo),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF167A63),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Pengajuan menunggu: ${formatRupiah(saldoTertahan)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Saldo tersedia: ${formatRupiah(saldoTersedia)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Nominal Penarikan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nominalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nominal penarikan',
                            prefixText: 'Rp ',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Minimal penarikan Rp1.000.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        CheckboxListTile(
                          value: konfirmasiPenarikan,
                          onChanged: sedangMengirim
                              ? null
                              : (value) {
                                  setState(() {
                                    konfirmasiPenarikan = value ?? false;
                                  });
                                },
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF167A63),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Saya yakin ingin mengajukan penarikan saldo.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: sedangMengirim ? null : prosesPenarikan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF167A63),
                              foregroundColor: Colors.white,
                            ),
                            child: sedangMengirim
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Ajukan Penarikan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Simpan kode verifikasi dan tunjukkan kepada petugas. '
                            'Saldo dipotong setelah pengajuan disetujui.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Pengajuan Saya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daftar pengajuan penarikan yang pernah Anda buat.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (pengajuan.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 42,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text('Belum ada pengajuan penarikan.'),
                        ],
                      ),
                    )
                  else
                    ...pengajuan.map((item) {
                      final status = item['status']?.toString() ?? 'pending';
                      final nominal =
                          double.tryParse((item['nominal'] ?? 0).toString()) ??
                          0;
                      final kode =
                          item['kode_verifikasi'] ??
                          item['kode_penarikan'] ??
                          '-';

                      final pending = status.toLowerCase() == 'pending';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatRupiah(nominal),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _warnaLatarStatus(status),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel(status),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _warnaTeksStatus(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tanggal: ${formatTanggal(item['tgl_pengajuan'] ?? item['tgl_penarikan'] ?? item['created_at'] ?? item['tanggal'])}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              'Kode verifikasi: $kode',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

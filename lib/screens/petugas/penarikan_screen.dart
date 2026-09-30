import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/app_styles.dart';
import 'package:bank_sampah_flutter/data/petugas_dummy_data.dart';
import 'package:bank_sampah_flutter/models/petugas_model.dart';

class PenarikanScreen extends StatefulWidget {
  const PenarikanScreen({super.key});

  @override
  State<PenarikanScreen> createState() => _PenarikanScreenState();
}

class _PenarikanScreenState extends State<PenarikanScreen> {
  final TextEditingController _kodeController = TextEditingController();
  DummyPenarikan? _pengajuan;
  DummyNasabah? _nasabah;
  String? _pesanValidasi;
  bool? _saldoCukup;

  @override
  void dispose() {
    _kodeController.dispose();
    super.dispose();
  }

  void _validasiKode() {
    final kode = _kodeController.text.trim().toUpperCase();

    if (kode.isEmpty) {
      setState(() {
        _pengajuan = null;
        _nasabah = null;
        _pesanValidasi = 'Masukkan kode pengajuan terlebih dahulu.';
        _saldoCukup = null;
      });
      return;
    }

    DummyPenarikan? ditemukan;
    for (final item in PetugasDummyData.penarikan) {
      if (item.kodePengajuan.toUpperCase() == kode) {
        ditemukan = item;
        break;
      }
    }

    if (ditemukan == null) {
      setState(() {
        _pengajuan = null;
        _nasabah = null;
        _pesanValidasi = 'Kode pengajuan tidak ditemukan.';
        _saldoCukup = null;
      });
      return;
    }

    DummyNasabah? nasabah;
    for (final item in PetugasDummyData.nasabah) {
      if (item.idNasabah == ditemukan!.idNasabah) {
        nasabah = item;
        break;
      }
    }

    final saldoCukup = nasabah != null && nasabah.saldo >= ditemukan.nominal;

    setState(() {
      _pengajuan = ditemukan;
      _nasabah = nasabah;
      _saldoCukup = saldoCukup;
      _pesanValidasi = ditemukan!.status == 'Menunggu'
          ? 'Pengajuan ditemukan.'
          : 'Pengajuan sudah ${ditemukan.status.toLowerCase()}.';
    });
  }

  Future<void> _proses(String statusBaru) async {
    final pengajuan = _pengajuan;
    final nasabah = _nasabah;

    if (pengajuan == null || nasabah == null) {
      return;
    }

    if (pengajuan.status != 'Menunggu') {
      _showMessage('Pengajuan ini sudah diproses.');
      return;
    }

    if (statusBaru == 'Disetujui' && !_saldoCukup!) {
      _showMessage('Saldo nasabah tidak mencukupi.', error: true);
      return;
    }

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isApprove = statusBaru == 'Disetujui';
        return AlertDialog(
          title: Text(isApprove ? 'Setujui Penarikan?' : 'Tolak Penarikan?'),
          content: Text(
            isApprove
                ? 'Saldo ${nasabah.nama} akan dikurangi ${rupiah(pengajuan.nominal)}.'
                : 'Pengajuan ${pengajuan.kodePengajuan} akan ditandai sebagai ditolak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? AppColors.primary : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isApprove ? 'Setujui' : 'Tolak'),
            ),
          ],
        );
      },
    );

    if (shouldContinue != true) {
      return;
    }

    setState(() {
      pengajuan.status = statusBaru;
      if (statusBaru == 'Disetujui') {
        nasabah.saldo -= pengajuan.nominal;
      }
      _saldoCukup = nasabah.saldo >= pengajuan.nominal;
      _pesanValidasi =
          'Pengajuan berhasil diproses sebagai ${pengajuan.status}.';
    });

    _showMessage('Status pengajuan diperbarui.');
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pengajuan = _pengajuan;
    final nasabah = _nasabah;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Verifikasi Penarikan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PageIntro(),
          const SizedBox(height: 16),
          TextField(
            controller: _kodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: AppDecorations.inputDecoration(
              'Kode Pengajuan',
              icon: Icons.qr_code_2_outlined,
            ).copyWith(hintText: 'Contoh: PGJ-001'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _validasiKode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Validasi Pengajuan'),
            ),
          ),
          if (_pesanValidasi != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color:
                    (_pengajuan != null
                            ? AppColors.secondary
                            : Colors.red.shade100)
                        .withOpacity(0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _pesanValidasi!,
                style: TextStyle(
                  color: _pengajuan != null
                      ? AppColors.primary
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (pengajuan != null && nasabah != null) ...[
            const SizedBox(height: 18),
            _PengajuanCard(
              pengajuan: pengajuan,
              nasabah: nasabah,
              saldoCukup: _saldoCukup ?? false,
            ),
            const SizedBox(height: 14),
            if (_saldoCukup == true && pengajuan.status == 'Menunggu')
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saldo mencukupi. Penarikan dapat disetujui.',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_saldoCukup == false && pengajuan.status == 'Menunggu')
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saldo tidak mencukupi. Pengajuan tidak dapat disetujui.',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            if (pengajuan.status == 'Menunggu')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _proses('Ditolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saldoCukup == true
                          ? () => _proses('Disetujui')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Setujui'),
                    ),
                  ),
                ],
              )
            else
              _StatusBadge(status: pengajuan.status),
          ],
        ],
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardBoxDecoration,
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Masukkan kode pengajuan untuk melihat data nasabah, nominal penarikan, dan saldo.',
              style: AppTextStyles.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PengajuanCard extends StatelessWidget {
  final DummyPenarikan pengajuan;
  final DummyNasabah nasabah;
  final bool saldoCukup;

  const _PengajuanCard({
    required this.pengajuan,
    required this.nasabah,
    required this.saldoCukup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pengajuan.kodePengajuan,
                  style: AppTextStyles.title,
                ),
              ),
              _StatusBadge(status: pengajuan.status),
            ],
          ),
          const Divider(height: 24),
          _DetailRow(label: 'Nasabah', value: nasabah.nama),
          _DetailRow(label: 'Nomor HP', value: nasabah.noHp),
          _DetailRow(
            label: 'Tanggal',
            value: tanggalIndonesia(pengajuan.tanggalPengajuan),
          ),
          _DetailRow(label: 'Saldo', value: rupiah(nasabah.saldo)),
          _DetailRow(label: 'Nominal', value: rupiah(pengajuan.nominal)),
          _DetailRow(
            label: 'Saldo cukup',
            value: saldoCukup ? 'Ya' : 'Tidak',
            valueColor: saldoCukup
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.subtitle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == 'Disetujui') {
      color = Colors.green.shade700;
    } else if (status == 'Ditolak') {
      color = Colors.red.shade700;
    } else {
      color = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

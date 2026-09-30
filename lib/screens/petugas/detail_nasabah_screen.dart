import 'package:flutter/material.dart';
import 'package:bank_sampah_flutter/app_styles.dart';
import 'package:bank_sampah_flutter/data/petugas_dummy_data.dart';
import 'package:bank_sampah_flutter/models/petugas_model.dart';

class DetailNasabahScreen extends StatelessWidget {
  final DummyNasabah nasabah;

  const DetailNasabahScreen({super.key, required this.nasabah});

  @override
  Widget build(BuildContext context) {
    final riwayatSetoran =
        PetugasDummyData.setoran
            .where((item) => item.idNasabah == nasabah.idNasabah)
            .toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    final riwayatPenarikan =
        PetugasDummyData.penarikan
            .where((item) => item.idNasabah == nasabah.idNasabah)
            .toList()
          ..sort((a, b) => b.tanggalPengajuan.compareTo(a.tanggalPengajuan));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Detail Nasabah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF388E3C)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 38, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  nasabah.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nasabah.noHp,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Saldo Nasabah',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(nasabah.saldo),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InfoSection(
            title: 'Data Nasabah',
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Nama',
                value: nasabah.nama,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Nomor HP',
                value: nasabah.noHp,
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Alamat',
                value: nasabah.alamat,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _HistorySection(
            title: 'Riwayat Setoran',
            emptyText: 'Belum ada setoran.',
            children: riwayatSetoran
                .map(
                  (item) => _HistoryTile(
                    title: item.namaSampah,
                    subtitle:
                        '${item.beratKg.toStringAsFixed(1)} Kg • ${tanggalIndonesia(item.tanggal)}',
                    amount: '+ ${rupiah(item.total)}',
                    amountColor: Colors.green.shade700,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          _HistorySection(
            title: 'Riwayat Penarikan',
            emptyText: 'Belum ada penarikan.',
            children: riwayatPenarikan
                .map(
                  (item) => _HistoryTile(
                    title: item.kodePengajuan,
                    subtitle:
                        '${tanggalIndonesia(item.tanggalPengajuan)} • ${item.status}',
                    amount: '- ${rupiah(item.nominal)}',
                    amountColor: Colors.orange.shade800,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: AppDecorations.cardBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(label, style: AppTextStyles.subtitle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<Widget> children;

  const _HistorySection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: AppDecorations.cardBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(emptyText, style: AppTextStyles.subtitle),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;

  const _HistoryTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.receipt_long_outlined,
          color: AppColors.primary,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: TextStyle(fontWeight: FontWeight.bold, color: amountColor),
      ),
    );
  }
}

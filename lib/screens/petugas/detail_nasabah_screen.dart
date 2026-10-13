import 'package:flutter/material.dart';

import 'package:bank_sampah_flutter/app_styles.dart' show tanggalIndonesia;
import 'package:bank_sampah_flutter/data/petugas_dummy_data.dart';
import 'package:bank_sampah_flutter/models/petugas_model.dart';

class DetailNasabahScreen extends StatelessWidget {
  final DummyNasabah nasabah;

  const DetailNasabahScreen({super.key, required this.nasabah});

  // ==========================================================
  // WARNA
  // ==========================================================

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color lightGreen = Color(0xFFE8F5F1);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7B8A89);

  // ==========================================================
  // FORMAT RUPIAH
  // ==========================================================

  String formatRupiah(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // RIWAYAT SETORAN
    // ========================================================

    final riwayatSetoran =
        PetugasDummyData.setoran
            .where((item) => item.idNasabah == nasabah.idNasabah)
            .toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    // ========================================================
    // RIWAYAT PENARIKAN
    // ========================================================

    final riwayatPenarikan =
        PetugasDummyData.penarikan
            .where((item) => item.idNasabah == nasabah.idNasabah)
            .toList()
          ..sort((a, b) => b.tanggalPengajuan.compareTo(a.tanggalPengajuan));

    return Scaffold(
      backgroundColor: background,

      // ======================================================
      // APP BAR
      // ======================================================
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Detail Nasabah',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          // ====================================================
          // PROFILE + SALDO
          // ====================================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF075B4F), Color(0xFF2E8B72)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                // AVATAR
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // NAMA
                Text(
                  nasabah.nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                // NOMOR HP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      color: Colors.white70,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      nasabah.noHp,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // GARIS
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Saldo Nasabah',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),

                const SizedBox(height: 4),

                Text(
                  formatRupiah(nasabah.saldo),
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

          // ====================================================
          // DATA NASABAH
          // ====================================================
          _SectionCard(
            title: 'Data Nasabah',
            icon: Icons.person_outline_rounded,
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
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

          // ====================================================
          // RIWAYAT SETORAN
          // ====================================================
          _HistorySection(
            title: 'Riwayat Setoran',
            icon: Icons.recycling_outlined,
            count: riwayatSetoran.length,
            emptyText: 'Belum ada setoran.',
            children: riwayatSetoran
                .map(
                  (item) => _HistoryTile(
                    icon: Icons.recycling_outlined,
                    iconBackground: lightGreen,
                    iconColor: primaryGreen,
                    title: item.namaSampah,
                    subtitle:
                        '${item.beratKg.toStringAsFixed(1)} Kg • '
                        '${tanggalIndonesia(item.tanggal)}',
                    amount: '+ ${formatRupiah(item.total)}',
                    amountColor: primaryGreen,
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // RIWAYAT PENARIKAN
          // ====================================================
          _HistorySection(
            title: 'Riwayat Penarikan',
            icon: Icons.account_balance_wallet_outlined,
            count: riwayatPenarikan.length,
            emptyText: 'Belum ada penarikan.',
            children: riwayatPenarikan
                .map(
                  (item) => _HistoryTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconBackground: const Color(0xFFFFF4E5),
                    iconColor: Colors.orange.shade800,
                    title: item.kodePengajuan,
                    subtitle:
                        '${tanggalIndonesia(item.tanggalPengajuan)} • '
                        '${item.status}',
                    amount: '- ${formatRupiah(item.nominal)}',
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

// ============================================================
// SECTION CARD
// ============================================================

class _SectionCard extends StatelessWidget {
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color textDark = Color(0xFF172033);

  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryGreen, size: 19),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ...children,
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7B8A89);

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: primaryGreen),

          const SizedBox(width: 10),

          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(color: textGrey, fontSize: 12),
            ),
          ),

          const SizedBox(width: 8),

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
      ),
    );
  }
}

// ============================================================
// HISTORY SECTION
// ============================================================

class _HistorySection extends StatelessWidget {
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7B8A89);
  static const Color primaryGreen = Color(0xFF2E8B72);

  final String title;
  final IconData icon;
  final int count;
  final String emptyText;
  final List<Widget> children;

  const _HistorySection({
    required this.title,
    required this.icon,
    required this.count,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryGreen, size: 19),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 8),
              child: Text(
                emptyText,
                style: const TextStyle(color: textGrey, fontSize: 12),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

// ============================================================
// HISTORY TILE
// ============================================================

class _HistoryTile extends StatelessWidget {
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7B8A89);

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;

  const _HistoryTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          // ICON
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(width: 11),

          // DETAIL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // NOMINAL
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

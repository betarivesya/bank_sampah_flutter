import 'package:flutter/material.dart';

import '../../app_styles.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ==========================================
      // APP BAR
      // ==========================================
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Profil Nasabah',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      // ==========================================
      // BODY
      // ==========================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // HEADER PROFIL
            // ==========================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // AVATAR
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // IDENTITAS
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nasabah',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Nasabah Bank Sampah Griya Ayu',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: AppColors.primary,
                            ),

                            SizedBox(width: 4),

                            Text(
                              'Nasabah Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
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

            const SizedBox(height: 18),

            // ==========================================
            // INFORMASI AKUN
            // ==========================================
            const Text(
              'Informasi Akun',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    icon: Icons.person_outline,
                    label: 'Nama Lengkap',
                    value: 'Nasabah',
                  ),

                  const Divider(height: 22),

                  _buildInfoItem(
                    icon: Icons.badge_outlined,
                    label: 'Nomor Anggota',
                    value: 'BSA-0001',
                  ),

                  const Divider(height: 22),

                  _buildInfoItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'nasabah@email.com',
                  ),

                  const Divider(height: 22),

                  _buildInfoItem(
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon',
                    value: '081234567890',
                  ),

                  const Divider(height: 22),

                  _buildInfoItem(
                    icon: Icons.location_on_outlined,
                    label: 'Alamat',
                    value: 'Alamat nasabah',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==========================================
            // SALDO
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Saat Ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Rp150.000',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==========================================
            // RINGKASAN AKTIVITAS
            // ==========================================
            const Text(
              'Ringkasan Aktivitas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildStatisticCard(
                    icon: Icons.recycling_outlined,
                    title: 'Total Setoran',
                    value: '12',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildStatisticCard(
                    icon: Icons.scale_outlined,
                    title: 'Total Sampah',
                    value: '38,50 kg',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildStatisticCard(
                    icon: Icons.payments_outlined,
                    title: 'Pendapatan',
                    value: 'Rp785.000',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // INFORMASI
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Data profil dan aktivitas Anda akan '
                      'ditampilkan sesuai dengan data yang '
                      'tersimpan pada sistem Bank Sampah Griya Ayu.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // INFO ITEM
  // ==========================================

  static Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STATISTIC CARD
  // ==========================================

  static Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

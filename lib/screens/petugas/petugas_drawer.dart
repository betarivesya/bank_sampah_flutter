import 'package:flutter/material.dart';

import '../../data/petugas_dummy_data.dart';
import 'nasabah_screen.dart';
import 'setoran_screen.dart';
import 'penarikan_screen.dart';

class PetugasDrawer extends StatelessWidget {
  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);

  final VoidCallback onRiwayat;
  final VoidCallback onLogout;

  const PetugasDrawer({
    super.key,
    required this.onRiwayat,
    required this.onLogout,
  });

  void bukaHalaman(BuildContext context, Widget halaman) {
    Navigator.pop(context);

    Navigator.push(context, MaterialPageRoute(builder: (context) => halaman));
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = PetugasDummyData.penarikan
        .where((item) => item.status == 'Menunggu')
        .length;

    return Drawer(
      backgroundColor: darkGreen,
      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER DRAWER
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Sampah',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Griya Ayu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: Colors.white24),

            const SizedBox(height: 18),

            // ==================================================
            // LABEL MENU
            // ==================================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 9),

            // ==================================================
            // DASHBOARD
            // ==================================================
            _drawerMenu(
              icon: Icons.home_rounded,
              title: 'Dashboard',
              active: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // ==================================================
            // DATA NASABAH
            // ==================================================
            _drawerMenu(
              icon: Icons.people_outline_rounded,
              title: 'Data Nasabah',
              onTap: () {
                bukaHalaman(context, const NasabahScreen());
              },
            ),

            // ==================================================
            // SETOR SAMPAH
            // ==================================================
            _drawerMenu(
              icon: Icons.recycling_outlined,
              title: 'Setor Sampah',
              onTap: () {
                bukaHalaman(context, const SetoranScreen());
              },
            ),

            // ==================================================
            // RIWAYAT
            // ==================================================
            _drawerMenu(
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Transaksi',
              onTap: () {
                Navigator.pop(context);
                onRiwayat();
              },
            ),

            // ==================================================
            // PENARIKAN
            // ==================================================
            _drawerMenu(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Penarikan Saldo',
              badge: totalPending > 0 ? '$totalPending' : null,
              onTap: () {
                bukaHalaman(context, const PenarikanScreen());
              },
            ),

            const Spacer(),

            // ==================================================
            // PROFILE PETUGAS
            // ==================================================
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // AVATAR
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: Color(0xFF57BF91),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 11),

                  // NAMA
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Petugas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Petugas Pelayanan',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  // LOGOUT
                  InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: onLogout,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF9B96),
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ITEM HAMBURGER
  // ==========================================================

  Widget _drawerMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool active = false,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: active ? primaryGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? Colors.white : Colors.white70,
                  size: 21,
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),

                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF716B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/petugas_dummy_data.dart';

class PetugasDrawer extends StatelessWidget {
  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);

  final String selectedMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onLogout;

  const PetugasDrawer({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
    required this.onLogout,
  });

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
            // HEADER
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

            // ==================================================
            // DAFTAR MENU YANG BISA DI-SCROLL
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),

                    // LABEL MENU
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

                    // DASHBOARD
                    _drawerMenu(
                      icon: Icons.home_rounded,
                      title: 'Dashboard',
                      active: selectedMenu == 'dashboard',
                      onTap: () {
                        onMenuSelected('dashboard');
                        Navigator.pop(context);
                      },
                    ),

                    // SETOR SAMPAH
                    _drawerMenu(
                      icon: Icons.recycling_outlined,
                      title: 'Setor Sampah',
                      active: selectedMenu == 'setoran',
                      onTap: () {
                        onMenuSelected('setoran');
                        Navigator.pop(context);
                      },
                    ),

                    // RIWAYAT TRANSAKSI
                    _drawerMenu(
                      icon: Icons.receipt_long_outlined,
                      title: 'Riwayat Transaksi',
                      active: selectedMenu == 'riwayat',
                      onTap: () {
                        onMenuSelected('riwayat');
                        Navigator.pop(context);
                      },
                    ),

                    // PENARIKAN SALDO
                    _drawerMenu(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Penarikan Saldo',
                      active: selectedMenu == 'penarikan',
                      badge: totalPending > 0 ? '$totalPending' : null,
                      onTap: () {
                        onMenuSelected('penarikan');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // PROFILE PETUGAS DAN LOGOUT
            // TETAP DI BAGIAN BAWAH DRAWER
            // ==================================================
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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

                  // NAMA PETUGAS
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
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ITEM MENU
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

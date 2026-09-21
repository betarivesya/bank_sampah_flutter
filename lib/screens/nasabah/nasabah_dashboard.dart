import 'package:flutter/material.dart';

import '../../app_styles.dart';
import 'riwayat_transaksi_screen.dart';
import 'penarikan_screen.dart';
import 'profil_screen.dart';

class NasabahDashboard extends StatefulWidget {
  const NasabahDashboard({super.key});

  @override
  State<NasabahDashboard> createState() => _NasabahDashboardState();
}

class _NasabahDashboardState extends State<NasabahDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _BerandaScreen(),
    RiwayatTransaksiScreen(),
    PenarikanScreen(),
    ProfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,

        backgroundColor: Colors.white,
        indicatorColor: AppColors.secondary.withValues(alpha: 0.35),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Penarikan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ======================================================
// HALAMAN BERANDA
// ======================================================

class _BerandaScreen extends StatelessWidget {
  const _BerandaScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Bank Sampah Griya Ayu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halo, Nasabah 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Selamat datang kembali!',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 24),

            // Kartu saldo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Anda',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rp150.000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _MenuCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Riwayat',
                    subtitle: 'Transaksi',
                    onTap: () {
                      // Bottom navigation index Riwayat
                      final dashboardState = context
                          .findAncestorStateOfType<_NasabahDashboardState>();

                      dashboardState?.setState(() {
                        dashboardState._selectedIndex = 1;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _MenuCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Penarikan',
                    subtitle: 'Saldo',
                    onTap: () {
                      final dashboardState = context
                          .findAncestorStateOfType<_NasabahDashboardState>();

                      dashboardState?.setState(() {
                        dashboardState._selectedIndex = 2;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// MENU CARD
// ======================================================

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.primary),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

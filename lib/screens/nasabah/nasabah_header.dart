import 'package:flutter/material.dart';

class NasabahHeader extends StatelessWidget {
  final int jumlahNotifikasi;
  final VoidCallback onNotifikasiTap;
  final VoidCallback onLogoutTap;

  const NasabahHeader({
    super.key,
    required this.jumlahNotifikasi,
    required this.onNotifikasiTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF167A63),
              size: 27,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'SIRAYA',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF172033),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bank Sampah Griya Ayu',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF167A63),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          _buildHeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: onNotifikasiTap,
            notificationCount: jumlahNotifikasi,
          ),

          const SizedBox(width: 8),

          _buildHeaderButton(icon: Icons.logout_rounded, onTap: onLogoutTap),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    int notificationCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: Icon(icon, color: const Color(0xFF172033), size: 21),
            ),
          ),
        ),

        if (notificationCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A3D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

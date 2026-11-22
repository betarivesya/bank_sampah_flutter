// lib/app_styles.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2D765D);
  static const Color primaryDark = Color(0xFF0F463D);
  static const Color primaryActive = Color(0xFF2F806B);
  static const Color secondary = Color(0xFF4FD1A5);
  static const Color background = Color(0xFFEDF1EF);
  static const Color backgroundLight = Color(0xFFF4F8F7);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF17332E);
  static const Color textSecondary = Color(0xFF71847F);
  static const Color border = Color(0xFFDFE6E3);
  static const Color success = Color(0xFF298357);
  static const Color error = Color(0xFFB42318);
  static const Color warning = Color(0xFFD88916);
  static const Color info = Color(0xFF23619A);
  static const Color accent = Color(0xFFD88916);
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle price = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );
}

class AppDecorations {
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  static BoxDecoration cardBoxDecoration = BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

String rupiah(num value, {bool desimal = false}) {
  final tanda = value < 0 ? '-' : '';
  final angka = desimal
      ? value.abs().toStringAsFixed(2)
      : value.abs().toStringAsFixed(0);

  final bagian = angka.split('.');
  final hasil = bagian[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]}.',
  );

  if (desimal) {
    return '${tanda}Rp$hasil,${bagian[1]}';
  }

  return '${tanda}Rp$hasil';
}

String tanggalIndonesia(DateTime date) {
  const bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${date.day} ${bulan[date.month - 1]} ${date.year}';
}

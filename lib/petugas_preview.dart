import 'package:flutter/material.dart';

import 'app_styles.dart';
import 'screens/petugas/petugas_dashboard.dart';

void main() {
  runApp(const PetugasPreviewApp());
}

class PetugasPreviewApp extends StatelessWidget {
  const PetugasPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bank Sampah - Petugas',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const PetugasDashboard(),
    );
  }
}

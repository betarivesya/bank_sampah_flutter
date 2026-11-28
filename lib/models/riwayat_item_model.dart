import 'package:flutter/material.dart';

import 'setoran_model.dart';

class RiwayatItem {
  final String namaNasabah;
  final String jenis;
  final double nominal;
  final DateTime tanggal;
  final IconData icon;
  final Color warna;
  final String? status;

  // Hanya transaksi setoran yang memiliki detail ini.
  final SetoranModel? setoran;

  RiwayatItem({
    required this.namaNasabah,
    required this.jenis,
    required this.nominal,
    required this.tanggal,
    required this.icon,
    required this.warna,
    this.status,
    this.setoran,
  });
}

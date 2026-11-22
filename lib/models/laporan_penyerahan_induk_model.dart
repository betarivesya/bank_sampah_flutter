class LaporanPenyerahanIndukModel {
  final int idLaporan;
  final String tanggalLaporan;
  final String status;
  final List<DetailLaporanPenyerahanModel> detailLaporan;

  LaporanPenyerahanIndukModel({
    required this.idLaporan,
    required this.tanggalLaporan,
    required this.status,
    required this.detailLaporan,
  });

  factory LaporanPenyerahanIndukModel.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['detail_laporan'] ?? json['detailLaporan'] ?? [];

    return LaporanPenyerahanIndukModel(
      idLaporan: _toInt(json['id_laporan'] ?? json['id']),
      tanggalLaporan: (json['tanggal_laporan'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
      detailLaporan: rawDetails is List
          ? rawDetails
                .whereType<Map>()
                .map(
                  (item) => DetailLaporanPenyerahanModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
    );
  }

  double get totalBerat =>
      detailLaporan.fold(0, (total, item) => total + item.beratFinal);

  double get totalNominal =>
      detailLaporan.fold(0, (total, item) => total + item.subtotal);

  int get jumlahJenisSampah => detailLaporan.length;
}

class DetailLaporanPenyerahanModel {
  final int idDetailLaporan;
  final String namaSampah;
  final double beratOtomatis;
  final double beratFinal;
  final double hargaPerKg;
  final double subtotal;

  DetailLaporanPenyerahanModel({
    required this.idDetailLaporan,
    required this.namaSampah,
    required this.beratOtomatis,
    required this.beratFinal,
    required this.hargaPerKg,
    required this.subtotal,
  });

  factory DetailLaporanPenyerahanModel.fromJson(Map<String, dynamic> json) {
    final jenis = json['jenis_sampah'] ?? json['jenisSampah'] ?? {};

    return DetailLaporanPenyerahanModel(
      idDetailLaporan: _toInt(json['id_detail_laporan'] ?? json['id']),
      namaSampah: jenis is Map
          ? (jenis['nama_sampah'] ?? 'Tidak diketahui').toString()
          : 'Tidak diketahui',
      beratOtomatis: _toDouble(json['berat_otomatis']),
      beratFinal: _toDouble(json['berat_kg']),
      hargaPerKg: _toDouble(json['harga_per_kg']),
      subtotal: _toDouble(json['subtotal']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

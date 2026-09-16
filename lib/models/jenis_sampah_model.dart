import 'harga_sampah_model.dart';

class JenisSampah {
  final int id;
  final String namaSampah;
  final List<HargaSampah> listHarga;

  JenisSampah({
    required this.id,
    required this.namaSampah,
    required this.listHarga,
  });

  factory JenisSampah.fromJson(Map<String, dynamic> json) {
    var rawHarga = json['harga'] ?? json['harga_sampah'] ?? json['list_harga'];
    List<HargaSampah> hargaList = [];

    if (rawHarga != null && rawHarga is List) {
      hargaList = rawHarga
          .map((h) => HargaSampah.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    return JenisSampah(
      id: json['id_jenis_sampah'] ?? json['id'] ?? 0,
      namaSampah: json['nama_sampah'] ?? json['nama_jenis'] ?? '',
      listHarga: hargaList,
    );
  }
}
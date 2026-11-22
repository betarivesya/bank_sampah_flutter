class JenisSampah {
  final int idJenisSampah;
  final String namaSampah;
  final double hargaPerKg;
  final double hargaPerGram;
  final String satuan;
  final bool status;
  final int? idHarga;

  JenisSampah({
    required this.idJenisSampah,
    required this.namaSampah,
    required this.hargaPerKg,
    required this.hargaPerGram,
    required this.satuan,
    required this.status,
    this.idHarga,
  });

  factory JenisSampah.fromJson(Map<String, dynamic> json) {
    final jenisData = json['jenis_sampah'] is Map
        ? Map<String, dynamic>.from(json['jenis_sampah'])
        : json;

    final hargaPerKg =
        double.tryParse((json['harga_per_kg'] ?? '0').toString()) ?? 0;

    return JenisSampah(
      idJenisSampah:
          int.tryParse(
            (json['id_jenis_sampah'] ?? jenisData['id_jenis_sampah'] ?? '0')
                .toString(),
          ) ??
          0,
      namaSampah:
          (json['nama_sampah'] ?? jenisData['nama_sampah'] ?? 'Tidak diketahui')
              .toString(),
      hargaPerKg: hargaPerKg,
      hargaPerGram:
          double.tryParse(
            (json['harga_per_gram'] ?? (hargaPerKg / 1000)).toString(),
          ) ??
          0,
      satuan: (json['satuan'] ?? 'gram').toString(),
      status:
          (json['status'] ?? jenisData['status']) == true ||
          (json['status'] ?? jenisData['status']).toString() == '1',
      idHarga: int.tryParse((json['id_harga'] ?? '').toString()),
    );
  }
}

class JenisSampah {
  final int idJenisSampah;
  final String namaSampah;
  final double hargaPerKg;
  final bool status;
  final int? idHarga;

  JenisSampah({
    required this.idJenisSampah,
    required this.namaSampah,
    required this.hargaPerKg,
    required this.status,
    this.idHarga,
  });

  factory JenisSampah.fromJson(Map<String, dynamic> json) {
    double harga = 0;
    int? idHarga;

    // Data harga dari relasi "harga"
    if (json['harga'] is List && (json['harga'] as List).isNotEmpty) {
      final hargaData = (json['harga'] as List).first;

      harga = double.tryParse(hargaData['harga_per_kg'].toString()) ?? 0;

      idHarga = int.tryParse(hargaData['id_harga'].toString());
    }

    return JenisSampah(
      idJenisSampah: int.parse(json['id_jenis_sampah'].toString()),
      namaSampah: json['nama_sampah'].toString(),
      hargaPerKg: harga,
      status: json['status'] == true || json['status'].toString() == '1',
      idHarga: idHarga,
    );
  }
}

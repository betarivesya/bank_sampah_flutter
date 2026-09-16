class HargaSampah {
  final int idHarga;
  final int idJenisSampah;
  final int hargaPerKg;

  HargaSampah({
    required this.idHarga,
    required this.idJenisSampah,
    required this.hargaPerKg,
  });

  factory HargaSampah.fromJson(Map<String, dynamic> json) {
    // Mengonversi data string/double desimal (seperti "1000.00") menjadi int secara aman
    var hargaRaw = json['harga_per_kg'] ?? json['harga'] ?? 0;
    int parsedHarga = 0;

    if (hargaRaw is num) {
      parsedHarga = hargaRaw.toInt();
    } else if (hargaRaw is String) {
      parsedHarga = double.tryParse(hargaRaw)?.toInt() ?? 0;
    }

    return HargaSampah(
      idHarga: json['id_harga'] ?? json['id'] ?? 0,
      idJenisSampah: json['id_jenis_sampah'] ?? 0,
      hargaPerKg: parsedHarga,
    );
  }
}
class JenisSampah {
  final int? id;
  final String namaJenis;

  JenisSampah({this.id, required this.namaJenis});

  factory JenisSampah.fromJson(Map<String, dynamic> json) {
    return JenisSampah(
      id: json['id_jenis_sampah'], // Disesuaikan dengan primary key
      namaJenis: json['nama_sampah'] ?? '', // Disesuaikan dengan nama kolom
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_sampah': namaJenis,
    };
  }
}
class SetoranModel {
  final int idSetoran;
  final int idNasabah;
  final int idPetugas;
  final int? idJenisSampah;
  final String namaNasabah;
  final String namaSampah;
  final String namaPetugas;
  final double totalBerat;
  final double hargaPerKg;
  final double totalNilai;
  final String tanggal;
  final String status;

  SetoranModel({
    required this.idSetoran,
    required this.idNasabah,
    required this.idPetugas,
    this.idJenisSampah,
    required this.namaNasabah,
    required this.namaSampah,
    required this.namaPetugas,
    required this.totalBerat,
    required this.hargaPerKg,
    required this.totalNilai,
    required this.tanggal,
    required this.status,
  });

  // Mengubah JSON menjadi SetoranModel, termasuk data relasi Laravel.
  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    // Membaca angka dari berbagai tipe data JSON.
    double angka(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    // Membaca ID dari JSON.
    int id(dynamic value) {
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    // Membaca objek relasi seperti nasabah dan petugas.
    Map<String, dynamic> relasi(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return {};
    }

    final nasabah = relasi(json['nasabah']);
    final petugas = relasi(json['petugas']);

    // Mengambil daftar rincian sampah dari relasi detail_setoran.
    final dynamic detailJson = json['detail_setoran'] ?? json['detailSetoran'];

    final List<Map<String, dynamic>> detail = detailJson is List
        ? detailJson
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : [];

    // Menghitung total berat dari seluruh rincian sampah.
    final beratDetail = detail.fold<double>(
      0,
      (total, item) => total + angka(item['total_berat']),
    );

    // Menghitung total nominal dari seluruh rincian sampah.
    final nominalDetail = detail.fold<double>(0, (total, item) {
      final berat = angka(item['total_berat']);
      final harga = angka(item['harga_per_kg']);

      return total +
          angka(item['total_nilai'] ?? item['subtotal'] ?? berat * harga);
    });

    // Menggabungkan nama jenis sampah dari seluruh rincian.
    final namaJenis = detail
        .map((item) {
          final jenis = relasi(item['jenis_sampah'] ?? item['jenisSampah']);

          return (jenis['nama_sampah'] ??
                  jenis['nama_jenis_sampah'] ??
                  item['nama_sampah'] ??
                  item['nama_jenis_sampah'] ??
                  '')
              .toString();
        })
        .where((nama) => nama.isNotEmpty)
        .toSet()
        .toList();

    // Menghitung rata-rata harga per kilogram.
    final hargaRataRata = beratDetail > 0 ? nominalDetail / beratDetail : 0.0;

    return SetoranModel(
      idSetoran: id(json['id_setoran'] ?? json['id']),
      idNasabah: id(json['id_pengguna_nasabah']),
      idPetugas: id(json['id_pengguna_petugas']),
      idJenisSampah: detail.isNotEmpty
          ? id(detail.first['id_jenis_sampah'])
          : json['id_jenis_sampah'] == null
          ? null
          : id(json['id_jenis_sampah']),

      // Mengambil nama dari relasi atau field langsung jika tersedia.
      namaNasabah:
          (json['nama_nasabah'] ??
                  nasabah['nama_lengkap'] ??
                  nasabah['nama'] ??
                  nasabah['name'] ??
                  '-')
              .toString(),

      namaSampah: namaJenis.isNotEmpty
          ? namaJenis.join(', ')
          : (json['nama_sampah'] ?? '-').toString(),

      namaPetugas:
          (json['nama_petugas'] ??
                  petugas['nama_lengkap'] ??
                  petugas['nama'] ??
                  petugas['name'] ??
                  '-')
              .toString(),

      // Mengutamakan nilai langsung, lalu menghitung dari detail.
      totalBerat: json['total_berat'] != null
          ? angka(json['total_berat'])
          : beratDetail,

      hargaPerKg: json['harga_per_kg'] != null
          ? angka(json['harga_per_kg'])
          : hargaRataRata,

      totalNilai: json['total_nilai'] != null
          ? angka(json['total_nilai'])
          : nominalDetail,

      tanggal:
          (json['tgl_setoran'] ??
                  json['tanggal_setoran'] ??
                  json['tanggal'] ??
                  '')
              .toString(),

      status: (json['status'] ?? '-').toString(),
    );
  }
}

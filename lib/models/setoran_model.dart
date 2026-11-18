class DetailSetoranModel {
  final int idJenisSampah;
  final String namaSampah;
  final double totalBerat;
  final double hargaPerKg;
  final double totalNilai;

  const DetailSetoranModel({
    required this.idJenisSampah,
    required this.namaSampah,
    required this.totalBerat,
    required this.hargaPerKg,
    required this.totalNilai,
  });

  factory DetailSetoranModel.fromJson(Map<String, dynamic> json) {
    double angka(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return DetailSetoranModel(
      idJenisSampah:
          int.tryParse(json['id_jenis_sampah']?.toString() ?? '') ?? 0,
      namaSampah: (json['nama_sampah'] ?? '-').toString(),
      totalBerat: angka(json['total_berat']),
      hargaPerKg: angka(json['harga_per_kg']),
      totalNilai: angka(json['total_nilai'] ?? json['subtotal']),
    );
  }
}

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
  final List<DetailSetoranModel> rincian;

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
    this.rincian = const [],
  });

  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    double angka(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int id(dynamic value) {
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    Map<String, dynamic> relasi(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return {};
    }

    final nasabah = relasi(json['nasabah']);
    final petugas = relasi(json['petugas']);

    final dynamic detailJson =
        json['jenis_sampah'] ?? json['detail_setoran'] ?? json['detailSetoran'];

    final List<DetailSetoranModel> rincian = detailJson is List
        ? detailJson
              .whereType<Map>()
              .map(
                (item) => DetailSetoranModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : [];

    final beratDetail = rincian.fold<double>(
      0,
      (total, item) => total + item.totalBerat,
    );

    final nominalDetail = rincian.fold<double>(
      0,
      (total, item) => total + item.totalNilai,
    );

    final namaJenis = rincian
        .map((item) => item.namaSampah)
        .where((nama) => nama.isNotEmpty && nama != '-')
        .toSet()
        .toList();

    final hargaRataRata = beratDetail > 0
        ? nominalDetail / (beratDetail / 1000)
        : 0.0;

    return SetoranModel(
      idSetoran: id(json['id_setoran'] ?? json['id']),
      idNasabah: id(
        json['id_pengguna_nasabah'] ??
            nasabah['id_pengguna_nasabah'] ??
            nasabah['id'],
      ),
      idPetugas: id(
        json['id_pengguna_petugas'] ??
            petugas['id_pengguna_petugas'] ??
            petugas['id'],
      ),
      idJenisSampah: rincian.isNotEmpty
          ? rincian.first.idJenisSampah
          : json['id_jenis_sampah'] == null
          ? null
          : id(json['id_jenis_sampah']),
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
      rincian: rincian,
    );
  }
}

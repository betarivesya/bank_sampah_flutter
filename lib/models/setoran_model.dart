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

  factory DetailSetoranModel.fromJson(
    Map<String, dynamic> json, {
    bool beratDalamKg = false,
  }) {
    double angka(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final beratAsli = angka(json['total_berat']);
    final harga = angka(json['harga_per_kg']);
    final beratGram = beratDalamKg ? beratAsli * 1000 : beratAsli;

    final jenisSampah = json['jenis_sampah'] is Map
        ? Map<String, dynamic>.from(json['jenis_sampah'])
        : <String, dynamic>{};

    final nama = json['nama_sampah'] ?? jenisSampah['nama_sampah'] ?? '-';

    final nilaiApi = json['total_nilai'] ?? json['subtotal'];

    return DetailSetoranModel(
      idJenisSampah:
          int.tryParse(json['id_jenis_sampah']?.toString() ?? '') ?? 0,
      namaSampah: nama.toString(),
      totalBerat: beratGram,
      hargaPerKg: harga,
      totalNilai: nilaiApi != null ? angka(nilaiApi) : beratAsli * harga,
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

  factory SetoranModel.fromJson(
    Map<String, dynamic> json, {
    bool beratDalamKg = false,
  }) {
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
        json['detail_setoran'] ?? json['detailSetoran'] ?? json['jenis_sampah'];

    final List<DetailSetoranModel> rincian = detailJson is List
        ? detailJson.whereType<Map>().map((item) {
            return DetailSetoranModel.fromJson(
              Map<String, dynamic>.from(item),
              beratDalamKg: beratDalamKg,
            );
          }).toList()
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

    final beratRingkasan = json['total_berat'] != null
        ? angka(json['total_berat']) * (beratDalamKg ? 1000 : 1)
        : beratDetail;

    final nominalRingkasan = json['total_nilai'] != null
        ? angka(json['total_nilai'])
        : nominalDetail;

    final hargaRataRata = beratRingkasan > 0
        ? nominalRingkasan / (beratRingkasan / 1000)
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
      totalBerat: beratRingkasan,
      hargaPerKg: json['harga_per_kg'] != null
          ? angka(json['harga_per_kg'])
          : hargaRataRata,
      totalNilai: nominalRingkasan,
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

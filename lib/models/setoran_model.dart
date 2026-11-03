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

  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    double parseDouble(dynamic value) =>
        double.tryParse(value?.toString() ?? '') ?? 0;

    return SetoranModel(
      idSetoran: parseInt(json['id_setoran']),
      idNasabah: parseInt(json['id_pengguna_nasabah']),
      idPetugas: parseInt(json['id_pengguna_petugas']),
      idJenisSampah: json['id_jenis_sampah'] == null
          ? null
          : parseInt(json['id_jenis_sampah']),
      namaNasabah: json['nama_nasabah']?.toString() ?? '-',
      namaSampah: json['nama_sampah']?.toString() ?? '-',
      namaPetugas: json['nama_petugas']?.toString() ?? '-',
      totalBerat: parseDouble(json['total_berat']),
      hargaPerKg: parseDouble(json['harga_per_kg']),
      totalNilai: parseDouble(json['total_nilai']),
      tanggal: json['tgl_setoran']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

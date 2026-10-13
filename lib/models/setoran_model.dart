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
    return SetoranModel(
      idSetoran: int.parse(json['id_setoran'].toString()),
      idNasabah: int.parse(json['id_pengguna_nasabah'].toString()),
      idPetugas: int.parse(json['id_pengguna_petugas'].toString()),
      idJenisSampah: json['id_jenis_sampah'] == null
          ? null
          : int.parse(json['id_jenis_sampah'].toString()),
      namaNasabah: json['nama_nasabah']?.toString() ?? '-',
      namaSampah: json['nama_sampah']?.toString() ?? '-',
      namaPetugas: json['nama_petugas']?.toString() ?? '-',
      totalBerat: double.parse(json['total_berat'].toString()),
      hargaPerKg: double.parse(json['harga_per_kg'].toString()),
      totalNilai: double.parse(json['total_nilai'].toString()),
      tanggal: json['tgl_setoran']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

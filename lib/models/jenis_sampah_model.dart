class JenisSampah {
  final int idJenisSampah;
  final String namaSampah;
  final double hargaPerGram;
  final String satuan;
  final bool status;
  final int? idHarga;

  JenisSampah({
    required this.idJenisSampah,
    required this.namaSampah,
    required this.hargaPerGram,
    required this.satuan,
    required this.status,
    this.idHarga,
  });

  factory JenisSampah.fromJson(Map<String, dynamic> json) {
    final hargaList = json['harga'] is List ? json['harga'] as List : [];

    // Pilih harga aktif terlebih dahulu.
    Map<String, dynamic> hargaData = {};

    if (hargaList.isNotEmpty) {
      final hargaAktif = hargaList.where((item) {
        final status = item['status'];
        return status == true || status.toString() == '1';
      }).toList();

      final selected = hargaAktif.isNotEmpty ? hargaAktif.last : hargaList.last;

      hargaData = Map<String, dynamic>.from(selected);
    } else if (json['harga'] is Map) {
      hargaData = Map<String, dynamic>.from(json['harga']);
    }

    // API saat ini menggunakan harga_per_gram.
    // harga_per_kg hanya menjadi fallback jika API mengirim field tersebut.
    final hargaPerGram = hargaData['harga_per_gram'] != null
        ? double.tryParse(hargaData['harga_per_gram'].toString()) ?? 0
        : (double.tryParse(
                    (hargaData['harga_per_kg'] ?? json['harga_per_kg'] ?? '0')
                        .toString(),
                  ) ??
                  0) /
              1000;

    final statusData = json['status'];

    return JenisSampah(
      idJenisSampah:
          int.tryParse((json['id_jenis_sampah'] ?? '0').toString()) ?? 0,
      namaSampah: (json['nama_sampah'] ?? 'Tidak diketahui').toString(),
      hargaPerGram: hargaPerGram,
      satuan: 'gram',
      status: statusData == true || statusData.toString() == '1',
      idHarga: int.tryParse((hargaData['id_harga'] ?? '').toString()),
    );
  }
}

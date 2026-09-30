class DummyNasabah {
  int idNasabah;
  String nama;
  String noHp;
  String alamat;
  double saldo;

  DummyNasabah({
    required this.idNasabah,
    required this.nama,
    required this.noHp,
    required this.alamat,
    required this.saldo,
  });
}

class DummyJenisSampah {
  final int idJenisSampah;
  final String namaSampah;
  final double hargaPerKg;

  DummyJenisSampah({
    required this.idJenisSampah,
    required this.namaSampah,
    required this.hargaPerKg,
  });
}

class DummySetoran {
  final int idSetoran;
  final int idNasabah;
  final int idJenisSampah;
  final String namaNasabah;
  final String namaSampah;
  final double beratKg;
  final double hargaPerKg;
  final double total;
  final DateTime tanggal;

  DummySetoran({
    required this.idSetoran,
    required this.idNasabah,
    required this.idJenisSampah,
    required this.namaNasabah,
    required this.namaSampah,
    required this.beratKg,
    required this.hargaPerKg,
    required this.total,
    required this.tanggal,
  });
}

class DummyPenarikan {
  final int idPenarikan;
  final int idNasabah;
  final String kodePengajuan;
  final String namaNasabah;
  final double nominal;
  final DateTime tanggalPengajuan;
  String status;

  DummyPenarikan({
    required this.idPenarikan,
    required this.idNasabah,
    required this.kodePengajuan,
    required this.namaNasabah,
    required this.nominal,
    required this.tanggalPengajuan,
    required this.status,
  });
}

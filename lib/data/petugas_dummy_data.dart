import '../models/petugas_model.dart';

class PetugasDummyData {
  static final List<DummyNasabah> nasabah = [
    DummyNasabah(
      idNasabah: 1,
      nama: 'Budi Santoso',
      noHp: '081234567890',
      alamat: 'Sumbersari, Jember',
      saldo: 125000,
    ),
    DummyNasabah(
      idNasabah: 2,
      nama: 'Siti Aminah',
      noHp: '082345678901',
      alamat: 'Kaliwates, Jember',
      saldo: 85000,
    ),
    DummyNasabah(
      idNasabah: 3,
      nama: 'Ahmad Fauzi',
      noHp: '083456789012',
      alamat: 'Patrang, Jember',
      saldo: 210000,
    ),
    DummyNasabah(
      idNasabah: 4,
      nama: 'Dewi Lestari',
      noHp: '084567890123',
      alamat: 'Pakusari, Jember',
      saldo: 150000,
    ),
    DummyNasabah(
      idNasabah: 5,
      nama: 'Rizky Maulana',
      noHp: '085678901234',
      alamat: 'Ajung, Jember',
      saldo: 95000,
    ),
  ];

  static final List<DummyJenisSampah> jenisSampah = [
    DummyJenisSampah(idJenisSampah: 1, namaSampah: 'Plastik', hargaPerKg: 3000),
    DummyJenisSampah(idJenisSampah: 2, namaSampah: 'Kertas', hargaPerKg: 2500),
    DummyJenisSampah(idJenisSampah: 3, namaSampah: 'Logam', hargaPerKg: 5000),
    DummyJenisSampah(
      idJenisSampah: 4,
      namaSampah: 'Minyak Jelantah',
      hargaPerKg: 4500,
    ),
  ];

  static final List<DummySetoran> setoran = [
    DummySetoran(
      idSetoran: 1,
      idNasabah: 1,
      idJenisSampah: 1,
      namaNasabah: 'Budi Santoso',
      namaSampah: 'Plastik',
      beratKg: 5,
      hargaPerKg: 3000,
      total: 15000,
      tanggal: DateTime(2026, 9, 18),
    ),
    DummySetoran(
      idSetoran: 2,
      idNasabah: 2,
      idJenisSampah: 2,
      namaNasabah: 'Siti Aminah',
      namaSampah: 'Kertas',
      beratKg: 4,
      hargaPerKg: 2500,
      total: 10000,
      tanggal: DateTime(2026, 9, 18),
    ),
    DummySetoran(
      idSetoran: 3,
      idNasabah: 3,
      idJenisSampah: 3,
      namaNasabah: 'Ahmad Fauzi',
      namaSampah: 'Logam',
      beratKg: 3,
      hargaPerKg: 5000,
      total: 15000,
      tanggal: DateTime(2026, 9, 19),
    ),
  ];

  static final List<DummyPenarikan> penarikan = [
    DummyPenarikan(
      idPenarikan: 1,
      idNasabah: 1,
      kodePengajuan: 'PGJ-001',
      namaNasabah: 'Budi Santoso',
      nominal: 50000,
      tanggalPengajuan: DateTime(2026, 9, 19),
      status: 'Menunggu',
    ),
    DummyPenarikan(
      idPenarikan: 2,
      idNasabah: 3,
      kodePengajuan: 'PGJ-002',
      namaNasabah: 'Ahmad Fauzi',
      nominal: 75000,
      tanggalPengajuan: DateTime(2026, 9, 19),
      status: 'Menunggu',
    ),
    DummyPenarikan(
      idPenarikan: 3,
      idNasabah: 2,
      kodePengajuan: 'PGJ-003',
      namaNasabah: 'Siti Aminah',
      nominal: 20000,
      tanggalPengajuan: DateTime(2026, 9, 17),
      status: 'Disetujui',
    ),
  ];

  static int get nextSetoranId {
    if (setoran.isEmpty) {
      return 1;
    }

    return setoran
            .map((item) => item.idSetoran)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }
}

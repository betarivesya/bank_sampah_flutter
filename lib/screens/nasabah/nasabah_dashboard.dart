import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/setoran_model.dart';
import '../../services/api_service.dart';

import 'nasabah_header.dart';
import 'nasabah_bottom_bar.dart';
import 'riwayat_transaksi_screen.dart';
import 'penarikan_screen.dart';
import 'harga_sampah_screen.dart';
import 'profil_screen.dart';
import '../auth/login_screen.dart';
import 'notifikasi_screen.dart';

class NasabahDashboard extends StatefulWidget {
  final int idNasabah;

  const NasabahDashboard({super.key, required this.idNasabah});

  @override
  State<NasabahDashboard> createState() => _NasabahDashboardState();
}

class _NasabahDashboardState extends State<NasabahDashboard> {
  // =========================================================
  // VARIABEL NOTIFIKASI
  // =========================================================

  int _jumlahNotifikasiBelumDibaca = 0;
  Timer? _timerNotifikasi;
  bool _sedangMemuatJumlahNotifikasi = false;

  // Menentukan menu yang sedang dipilih pada bottom navigation.
  int _selectedIndex = 0;

  // =========================================================
  // DATA YANG DITERIMA DARI API
  // =========================================================

  Map<String, dynamic> _dataNasabah = {};
  List<SetoranModel> _setoranSaya = [];
  List<Map<String, dynamic>> _penarikanSaya = [];

  // Menyimpan URL foto profil dari API.
  // Jika belum ada foto, aplikasi akan menampilkan inisial nama.
  String? _fotoProfilUrl;

  bool _loadingDashboard = true;
  String? _errorDashboard;

  // Mengambil nama nasabah dari beberapa kemungkinan nama field API.
  String get namaNasabah => _ambilTeks([
    'nama_lengkap',
    'nama_nasabah',
    'nama_pengguna',
    'nama',
    'name',
  ], fallback: 'Nasabah');

  // Mengambil nomor anggota.
  // Jika API tidak mengirim nomor anggota, gunakan ID nasabah sebagai pengganti.
  String get nomorAnggota => _ambilTeks([
    'nomor_anggota',
    'no_anggota',
    'kode_nasabah',
    'nomor_nasabah',
  ], fallback: 'BSA-${widget.idNasabah.toString().padLeft(4, '0')}');

  // Mengambil saldo dari data API.
  double get saldo => _ambilAngka(['saldo', 'saldo_tabungan', 'saldo_akhir']);

  // Menghitung jumlah transaksi setoran.
  int get totalSetoran => _setoranSaya.length;

  // Statistik Setoran tahun
  int get tahunAktif => DateTime.now().year;

  // Target berat setiap jenis sampah
  static const double targetSetoranPerJenis = 500000;

  // Menjumlahkan seluruh berat sampah yang pernah disetorkan.
  double get totalSampah =>
      _setoranSaya.fold(0.0, (total, item) => total + item.totalBerat);

  // Menjumlahkan nilai dari seluruh transaksi setoran.
  double get totalPendapatan =>
      _setoranSaya.fold(0.0, (total, item) => total + item.totalNilai);

  // Membaca nilai teks berdasarkan beberapa kemungkinan nama field.
  String _ambilTeks(List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = _dataNasabah[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  // Membaca angka dari API.
  // Nilai yang tidak dapat dikonversi akan dianggap 0.
  double _ambilAngka(List<String> keys) {
    for (final key in keys) {
      final value = _dataNasabah[key];

      if (value != null) {
        return double.tryParse(value.toString()) ?? 0.0;
      }
    }

    return 0.0;
  }

  // =========================================================
  // INISIALISASI DAN SIKLUS HIDUP HALAMAN
  // =========================================================

  @override
  void initState() {
    super.initState();

    // Memuat data dashboard ketika halaman pertama kali dibuka.
    _muatDashboard();

    // Memuat jumlah notifikasi yang belum dibaca.
    _muatJumlahNotifikasi();

    // Memeriksa kembali notifikasi setiap 30 detik.
    _timerNotifikasi = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _muatJumlahNotifikasi(),
    );
  }

  @override
  void dispose() {
    // Menghentikan timer agar tidak berjalan setelah halaman ditutup.
    _timerNotifikasi?.cancel();
    super.dispose();
  }

  // =========================================================
  // MEMUAT JUMLAH NOTIFIKASI
  // =========================================================

  Future<void> _muatJumlahNotifikasi() async {
    // Mencegah permintaan API yang sama berjalan bersamaan.
    if (_sedangMemuatJumlahNotifikasi) return;

    _sedangMemuatJumlahNotifikasi = true;

    try {
      final hasil = await ApiService.getNotifikasiNasabah(widget.idNasabah);

      final dynamic data = hasil['data'];

      if (data is! List) return;

      final notifikasi = data
          .whereType<Map>()
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();

      // Menghitung notifikasi yang belum dibaca.
      final jumlah = notifikasi.where((item) {
        final nilai = item['dibaca'];

        final sudahDibaca =
            nilai == true ||
            nilai.toString() == '1' ||
            nilai.toString().toLowerCase() == 'true';

        return !sudahDibaca;
      }).length;

      if (!mounted) return;

      if (_jumlahNotifikasiBelumDibaca != jumlah) {
        setState(() {
          _jumlahNotifikasiBelumDibaca = jumlah;
        });
      }
    } catch (e) {
      debugPrint('Gagal memperbarui jumlah notifikasi: $e');
    } finally {
      _sedangMemuatJumlahNotifikasi = false;
    }
  }

  // =========================================================
  // MEMUAT SELURUH DATA DASHBOARD
  // =========================================================

  Future<void> _muatDashboard() async {
    if (!mounted) return;

    setState(() {
      _loadingDashboard = true;
      _errorDashboard = null;
    });

    try {
      // Mengambil data nasabah, setoran, penarikan, dan profil secara bersamaan.
      // Endpoint profil digunakan untuk memperoleh foto_profil_url.
      final hasil = await Future.wait([
        ApiService.getProfilNasabah(widget.idNasabah),
        ApiService.getRiwayatSetoranNasabah(widget.idNasabah),
        ApiService.getRiwayatPenarikanNasabah(widget.idNasabah),
      ]);

      final profilNasabah = hasil[0] as Map<String, dynamic>;
      final semuaSetoran = hasil[1] as List<SetoranModel>;
      final semuaPenarikan = hasil[2] as List<Map<String, dynamic>>;

      // Mengambil alamat foto yang dikirim oleh Laravel.
      final dynamic fotoApi = profilNasabah['foto_profil_url'];
      final fotoUrl = fotoApi?.toString();

      // Mengambil transaksi setoran milik nasabah yang sedang login.
      final setoranNasabah = semuaSetoran;

      // Mengurutkan setoran dari tanggal terbaru.
      setoranNasabah.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      // Mengurutkan riwayat penarikan dari yang terbaru.
      semuaPenarikan.sort((a, b) {
        final tanggalA = (a['tgl_pengajuan'] ?? '').toString();
        final tanggalB = (b['tgl_pengajuan'] ?? '').toString();

        final perbandingan = tanggalB.compareTo(tanggalA);

        if (perbandingan != 0) return perbandingan;

        final idA = int.tryParse(a['id_penarikan']?.toString() ?? '') ?? 0;
        final idB = int.tryParse(b['id_penarikan']?.toString() ?? '') ?? 0;

        return idB.compareTo(idA);
      });

      if (!mounted) return;

      setState(() {
        // Menggabungkan data daftar nasabah dengan data profil.
        // Data profil ditambahkan agar foto dan field profil tersedia.
        _dataNasabah = profilNasabah;

        _setoranSaya = setoranNasabah;
        _penarikanSaya = semuaPenarikan;
        _fotoProfilUrl = fotoUrl;
        _loadingDashboard = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat dashboard: $e');

      if (!mounted) return;

      setState(() {
        _loadingDashboard = false;
        _errorDashboard = 'Gagal memuat data. Periksa koneksi dan server API.';
      });
    }
  }

  // =========================================================
  // FOTO PROFIL NASABAH
  // =========================================================

  Widget _buildFotoNasabah({double ukuran = 48}) {
    // Jika URL foto tersedia, tampilkan gambar dari server.
    // Jika URL kosong atau gambar gagal dimuat, tampilkan inisial nama.
    final url = _fotoProfilUrl?.trim();

    if (url != null && url.isNotEmpty && url != 'null') {
      return ClipOval(
        child: Image.network(
          url,
          width: ukuran,
          height: ukuran,
          fit: BoxFit.cover,

          // Jika gambar gagal dimuat, gunakan avatar inisial.
          errorBuilder: (context, error, stackTrace) {
            return _buildInisialNasabah(ukuran: ukuran);
          },

          // Menampilkan avatar sementara saat gambar sedang dimuat.
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return _buildInisialNasabah(ukuran: ukuran);
          },
        ),
      );
    }

    // Avatar cadangan apabila nasabah belum mengunggah foto.
    return _buildInisialNasabah(ukuran: ukuran);
  }

  Widget _buildInisialNasabah({double ukuran = 48}) {
    // Mengambil huruf pertama nama untuk avatar cadangan.
    final nama = namaNasabah.trim();
    final inisial = nama.isNotEmpty ? nama[0].toUpperCase() : 'N';

    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF2D765D),
        shape: BoxShape.circle,
      ),
      child: Text(
        inisial,
        style: TextStyle(
          color: Colors.white,
          fontSize: ukuran * 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // NAVIGASI
  // =========================================================

  void _onItemTapped(int index) {
    final indexSebelumnya = _selectedIndex;

    setState(() {
      _selectedIndex = index;
    });

    // Muat ulang dashboard ketika kembali dari Profil atau Penarikan.
    if ((indexSebelumnya == 2 || indexSebelumnya == 3) && index == 0) {
      _muatDashboard();
    }
  }

  // Membuka halaman notifikasi dan memperbarui jumlah setelah kembali.
  Future<void> _showNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotifikasiScreen(idNasabah: widget.idNasabah),
      ),
    );

    if (!mounted) return;

    await _muatJumlahNotifikasi();
  }

  // Menampilkan dialog konfirmasi sebelum logout.
  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar'),
          content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  // Konfirmasi ketika pengguna menekan tombol kembali dari beranda.
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar Aplikasi'),
          content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  // Menentukan halaman berdasarkan menu yang dipilih.
  Widget _buildPage() {
    switch (_selectedIndex) {
      case 1:
        return RiwayatTransaksiScreen(idNasabah: widget.idNasabah);

      case 2:
        return PenarikanScreen(
          key: UniqueKey(), // Membuat halaman penarikan selalu dimuat ulang.
          idNasabah: widget.idNasabah,
        );

      case 3:
        return ProfilScreen(idNasabah: widget.idNasabah);

      default:
        return _buildHome();
    }
  }

  // =========================================================
  // BERANDA / DASHBOARD
  // =========================================================

  Widget _buildHome() {
    return SafeArea(
      child: Column(
        children: [
          NasabahHeader(
            jumlahNotifikasi: _jumlahNotifikasiBelumDibaca,
            onNotifikasiTap: _showNotifications,
            onLogoutTap: _logout,
          ),
          const SizedBox(height: 15),
          Expanded(
            child: RefreshIndicator(
              // Tarik layar ke bawah untuk memuat ulang data.
              onRefresh: _muatDashboard,
              color: const Color(0xFF2D765D),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileGreeting(),
                    const SizedBox(height: 25),
                    _buildBalanceCard(),
                    const SizedBox(height: 16),
                    _buildStatistics(),
                    const SizedBox(height: 18),
                    _buildStatistikSetoranTahunan(),
                    const SizedBox(height: 18),
                    _buildHargaSampahShortcut(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Transaksi Setoran Terbaru',
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTransactionCard(),
                    const SizedBox(height: 20),
                    _buildWithdrawalCard(),
                    const SizedBox(height: 20),
                    _buildLatestWithdrawal(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SELAMAT DATANG NASABAH
  // =========================================================

  Widget _buildProfileGreeting() {
    return Row(
      children: [
        _buildFotoNasabah(ukuran: 48),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang,',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 3),
              Text(
                namaNasabah,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // KARTU SALDO
  // =========================================================

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D765D), Color(0xFF2D765D)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D765D).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Saldo Saat Ini',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatRupiah(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Saldo yang tersedia',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Berpindah ke menu penarikan.
                setState(() {
                  _selectedIndex = 2;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Tarik Saldo  →',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATISTIK NASABAH
  // =========================================================

  Widget _buildStatistics() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStatisticCard(
            title: 'Total Setoran',
            value: '$totalSetoran',
            subtitle: 'Transaksi',
            icon: Icons.recycling_rounded,
            iconColor: const Color(0xFF3B82F6),
            backgroundColor: const Color(0xFFEFF5FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatisticCard(
            title: 'Total Sampah',
            value: '$totalSampah',
            subtitle: 'Berat Sampah',
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFF28C28),
            backgroundColor: const Color(0xFFFFF4E7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatisticCard(
            title: 'Total Pendapatan',
            value: _formatRupiah(totalPendapatan),
            subtitle: 'Hasil Setoran',
            icon: Icons.payment_outlined,
            iconColor: const Color(0xFF16805F),
            backgroundColor: const Color(0xFFEAF7F1),
          ),
        ),
      ],
    );
  }

  // Komponen satu kartu statistik agar desain semua kartu konsisten.
  Widget _buildStatisticCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATISTIK SETORAN TAHUNAN
  // =========================================================

  Widget _buildStatistikSetoranTahunan() {
    final Map<String, double> statistikJenisSampah = {};

    // Ambil data setoran pada tahun berjalan.
    for (final setoran in _setoranSaya) {
      final tanggal = DateTime.tryParse(setoran.tanggal);

      if (tanggal == null || tanggal.year != tahunAktif) {
        continue;
      }

      // Hitung berat berdasarkan rincian setiap jenis sampah.
      for (final detail in setoran.rincian) {
        final namaJenis = detail.namaSampah.trim();

        if (namaJenis.isEmpty || namaJenis == '-') {
          continue;
        }

        statistikJenisSampah[namaJenis] =
            (statistikJenisSampah[namaJenis] ?? 0) + detail.totalBerat;
      }
    }

    // Urutkan dari berat setoran terbesar.
    final daftarStatistik = statistikJenisSampah.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul statistik.
          Text(
            'Statistik Setoran $tahunAktif',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          // Jika belum ada data setoran.
          if (daftarStatistik.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada data setoran tahun ini.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            // Daftar jenis sampah yang bisa di-scroll.
            SizedBox(
              height: 220,
              child: Scrollbar(
                child: ListView.separated(
                  itemCount: daftarStatistik.length,
                  padding: const EdgeInsets.only(right: 8),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = daftarStatistik[index];

                    final progress = (item.value / targetSetoranPerJenis).clamp(
                      0.0,
                      1.0,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_formatAngka(item.value)} / '
                              '${_formatAngka(targetSetoranPerJenis)} gram',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Format angka dengan titik sebagai pemisah ribuan.
  String _formatAngka(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  // =========================================================
  // JUDUL BAGIAN
  // =========================================================

  Widget _buildSectionHeader({required String title, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17332E),
            ),
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text(
              'Lihat semua',
              style: TextStyle(
                color: Color(0xFF2D765D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // HARGA SAMPAH
  // =========================================================

  Widget _buildHargaSampahShortcut() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HargaSampahScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDFE6E3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.price_change_rounded,
                color: Color(0xFF2D765D),
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga Sampah',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17332E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lihat harga setiap jenis sampah',
                    style: TextStyle(fontSize: 12, color: Color(0xFF71847F)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF71847F)),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DAFTAR TRANSAKSI SETORAN TERBARU
  // =========================================================

  Widget _buildTransactionCard() {
    // Hanya menampilkan maksimal tiga transaksi terbaru.
    final transaksi = _setoranSaya.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDFE6E3)),
      ),
      child: transaksi.isEmpty
          ? _buildEmptyContent(
              icon: Icons.receipt_long_outlined,
              message: 'Belum ada transaksi setoran.',
            )
          : Column(
              children: [
                for (int i = 0; i < transaksi.length; i++) ...[
                  _buildTransactionItem(
                    code: transaksi[i].namaSampah,
                    date: _formatTanggalDashboard(transaksi[i].tanggal),
                    weight:
                        '${transaksi[i].totalBerat.toStringAsFixed(2)} gram',
                    amount: transaksi[i].totalNilai,
                    status: transaksi[i].status,
                  ),
                  if (i < transaksi.length - 1) const Divider(height: 24),
                ],
              ],
            ),
    );
  }

  // Tampilan satu transaksi setoran.
  Widget _buildTransactionItem({
    required String code,
    required String date,
    required String weight,
    required double amount,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Color(0xFF2D765D),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$date • $weight',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+ ${_formatRupiah(amount)}',
              style: const TextStyle(
                color: Color(0xFF2D765D),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              status.isEmpty ? '-' : status,
              style: const TextStyle(color: Color(0xFF2D765D), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // AJAKAN MELAKUKAN PENARIKAN
  // =========================================================

  Widget _buildWithdrawalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D765D), Color(0xFF2D765D)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Butuh uang dari saldo?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ajukan penarikan saldo tabungan Anda melalui menu penarikan.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    // Berpindah ke halaman penarikan.
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2D765D),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ajukan Penarikan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PENARIKAN TERBARU
  // =========================================================

  Widget _buildLatestWithdrawal() {
    final penarikan = _penarikanSaya.isEmpty ? null : _penarikanSaya.first;

    // Mengambil nominal dari field yang tersedia di respons API.
    final nominal =
        double.tryParse(
          (penarikan?['nominal'] ??
                  penarikan?['jumlah'] ??
                  penarikan?['jumlah_penarikan'] ??
                  0)
              .toString(),
        ) ??
        0.0;

    final status = (penarikan?['status'] ?? 'Menunggu').toString();

    final tanggal = (penarikan?['tgl_pengajuan'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDFE6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Penarikan Terbaru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Membuka menu riwayat penarikan.
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
                child: const Text(
                  'Riwayat',
                  style: TextStyle(color: Color(0xFF2D765D), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (penarikan == null)
            _buildEmptyContent(
              icon: Icons.receipt_long_outlined,
              message: 'Belum ada pengajuan penarikan.',
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF2D765D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengajuan Penarikan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTanggalDashboard(tanggal),
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          status,
                          style: const TextStyle(
                            color: Color(0xFF2D765D),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatRupiah(nominal),
                    style: const TextStyle(
                      color: Color(0xFF2D765D),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Tampilan ketika belum ada data transaksi.
  Widget _buildEmptyContent({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF9CA3AF), size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FORMAT TANGGAL
  // =========================================================

  String _formatTanggalDashboard(String tanggal) {
    if (tanggal.isEmpty) return '-';

    try {
      final date = DateTime.parse(tanggal);

      const bulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      // Jika format tanggal tidak sesuai, tampilkan nilai asli dari API.
      return tanggal;
    }
  }

  // =========================================================
  // FORMAT RUPIAH
  // =========================================================

  String _formatRupiah(double value) {
    // Menggunakan titik sebagai pemisah ribuan, contoh Rp 10.000.
    final formatted = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');

    return 'Rp $formatted';
  }

  // =========================================================
  // BUILD UTAMA
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Mencegah aplikasi langsung tertutup saat tombol kembali ditekan.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Jika sedang di halaman lain, tombol kembali mengarah ke beranda.
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          // Jika sudah di beranda, tampilkan konfirmasi keluar.
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8F7),

        // Menampilkan indikator loading, pesan error, atau halaman yang dipilih.
        body: _loadingDashboard
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2D765D)),
              )
            : _errorDashboard != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFF71847F),
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorDashboard!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _muatDashboard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : _buildPage(),

        // Navigasi utama yang selalu muncul di bagian bawah layar.
        bottomNavigationBar: NasabahBottomBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/setoran_model.dart';
import '../../services/api_service.dart';

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
    'nama_nasabah',
    'nama_pengguna',
    'nama_lengkap',
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
        ApiService.getNasabah(),
        ApiService.getSetoran(),
        ApiService.getRiwayatPenarikanNasabah(widget.idNasabah),
        ApiService.getProfilNasabah(widget.idNasabah),
      ]);

      final daftarNasabah = hasil[0] as List<Map<String, dynamic>>;
      final semuaSetoran = hasil[1] as List<SetoranModel>;
      final semuaPenarikan = hasil[2] as List<Map<String, dynamic>>;
      final profilNasabah = hasil[3] as Map<String, dynamic>;

      // Mengambil alamat foto yang dikirim oleh Laravel.
      final dynamic fotoApi = profilNasabah['foto_profil_url'];
      final fotoUrl = fotoApi?.toString();

      // Mencari data nasabah yang ID-nya sesuai dengan pengguna yang login.
      Map<String, dynamic>? nasabah;

      for (final item in daftarNasabah) {
        final id = int.tryParse(
          (item['id_pengguna_nasabah'] ?? item['id_nasabah'] ?? item['id'])
              .toString(),
        );

        if (id == widget.idNasabah) {
          nasabah = item;
          break;
        }
      }

      // Mengambil transaksi setoran milik nasabah yang sedang login.
      final setoranNasabah = semuaSetoran
          .where((item) => item.idNasabah == widget.idNasabah)
          .toList();

      // Mengurutkan setoran dari tanggal terbaru.
      setoranNasabah.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      // Mengurutkan riwayat penarikan dari yang terbaru.
      semuaPenarikan.sort((a, b) {
        final tanggalA =
            (a['created_at'] ?? a['tgl_penarikan'] ?? a['tanggal'] ?? '')
                .toString();

        final tanggalB =
            (b['created_at'] ?? b['tgl_penarikan'] ?? b['tanggal'] ?? '')
                .toString();

        return tanggalB.compareTo(tanggalA);
      });

      if (!mounted) return;

      setState(() {
        // Menggabungkan data daftar nasabah dengan data profil.
        // Data profil ditambahkan agar foto dan field profil tersedia.
        _dataNasabah = {...?nasabah, ...profilNasabah};

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
        color: Color(0xFF2E9B7D),
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
    setState(() {
      _selectedIndex = index;
    });
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
        return PenarikanScreen(idNasabah: widget.idNasabah);

      case 3:
        return const HargaSampahScreen();

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
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              // Tarik layar ke bawah untuk memuat ulang data.
              onRefresh: _muatDashboard,
              color: const Color(0xFF167A63),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    _buildBalanceCard(),
                    const SizedBox(height: 16),
                    _buildStatistics(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Transaksi Terbaru',
                      onTap: () {
                        // Membuka halaman profil saat tombol "Lihat semua"
                        // pada bagian ini ditekan, mengikuti kode awal.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfilScreen(idNasabah: widget.idNasabah),
                          ),
                        );
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
  // HEADER APLIKASI
  // =========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Color(0xFF167A63),
              size: 25,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Bank Sampah',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                Text(
                  'Griya Ayu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF167A63),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: _showNotifications,
            notificationCount: _jumlahNotifikasiBelumDibaca,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(icon: Icons.logout_rounded, onTap: _logout),
        ],
      ),
    );
  }

  // Tombol ikon pada header, termasuk badge jumlah notifikasi.
  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    int notificationCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: Icon(icon, color: const Color(0xFF172033), size: 21),
            ),
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A3D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // KARTU PROFIL NASABAH
  // =========================================================

  Widget _buildProfileCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        // Membuka halaman profil untuk melihat atau mengubah data nasabah.
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilScreen(idNasabah: widget.idNasabah),
          ),
        );

        // Setelah kembali dari halaman profil, ambil data terbaru.
        // Ini membuat foto yang baru diganti dapat muncul di dashboard.
        if (mounted) {
          await _muatDashboard();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7ECEA)),
        ),
        child: Row(
          children: [
            // Foto profil dari server atau inisial jika belum ada foto.
            _buildFotoNasabah(ukuran: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaNasabah,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nomorAnggota,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // KARTU SALDO
  // =========================================================

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176B59), Color(0xFF2E9277)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B59).withValues(alpha: 0.20),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 18,
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
          const SizedBox(height: 18),
          Text(
            _formatRupiah(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Saldo yang tersedia',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 18),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildStatisticCard(
          title: 'Total Setoran',
          value: '$totalSetoran',
          subtitle: 'Seluruh transaksi setoran',
          icon: Icons.recycling_rounded,
          iconColor: const Color(0xFF3B82F6),
          backgroundColor: const Color(0xFFEFF5FF),
        ),
        _buildStatisticCard(
          title: 'Total Sampah',
          value: '${totalSampah.toStringAsFixed(2)} kg',
          subtitle: 'Total berat sampah',
          icon: Icons.delete_outline_rounded,
          iconColor: const Color(0xFFF28C28),
          backgroundColor: const Color(0xFFFFF4E7),
        ),
        _buildStatisticCard(
          title: 'Total Pendapatan',
          value: _formatRupiah(totalPendapatan),
          subtitle: 'Hasil seluruh setoran',
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFF16805F),
          backgroundColor: const Color(0xFFEAF7F1),
        ),
        _buildStatisticCard(
          title: 'Tahun Aktif',
          value: '2026',
          subtitle: 'Statistik tahun ini',
          icon: Icons.calendar_month_outlined,
          iconColor: const Color(0xFF8B5CF6),
          backgroundColor: const Color(0xFFF3EEFF),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
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
              color: Color(0xFF172033),
            ),
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text(
              'Lihat semua',
              style: TextStyle(
                color: Color(0xFF167A63),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
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
        border: Border.all(color: const Color(0xFFE8ECEA)),
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
                    code:
                        'ST-${transaksi[i].idSetoran.toString().padLeft(5, '0')}',
                    date: _formatTanggalDashboard(transaksi[i].tanggal),
                    weight: '${transaksi[i].totalBerat.toStringAsFixed(2)} kg',
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
            color: const Color(0xFFEAF7F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Color(0xFF16805F),
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
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
                color: Color(0xFF16805F),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              status.isEmpty ? '-' : status,
              style: const TextStyle(color: Color(0xFF16805F), fontSize: 10),
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
          colors: [Color(0xFF195E4F), Color(0xFF2C806B)],
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
                    foregroundColor: const Color(0xFF195E4F),
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

    final tanggal =
        (penarikan?['created_at'] ??
                penarikan?['tgl_penarikan'] ??
                penarikan?['tanggal'] ??
                '')
            .toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECEA)),
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
                  style: TextStyle(color: Color(0xFF167A63), fontSize: 11),
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
                color: const Color(0xFFF7F9F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF16805F),
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
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          status,
                          style: const TextStyle(
                            color: Color(0xFF16805F),
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
                      color: Color(0xFF16805F),
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
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
  // BOTTOM NAVIGATION
  // =========================================================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE0F2EB),
      elevation: 8,
      height: 68,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Transaksi',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Penarikan',
        ),
        NavigationDestination(
          icon: Icon(Icons.price_change_outlined),
          selectedIcon: Icon(Icons.price_change_rounded),
          label: 'Harga Sampah',
        ),
      ],
    );
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
        backgroundColor: const Color(0xFFF7F9F8),

        // Menampilkan indikator loading, pesan error, atau halaman yang dipilih.
        body: _loadingDashboard
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF167A63)),
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
                        color: Colors.grey,
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
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }
}

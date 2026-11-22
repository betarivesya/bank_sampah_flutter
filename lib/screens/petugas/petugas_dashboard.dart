import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class PetugasDashboard extends StatefulWidget {
  final Function(String) onMenuSelected;

  const PetugasDashboard({super.key, required this.onMenuSelected});

  // ============================================================
  // WARNA DASHBOARD
  // ============================================================

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color background = Color(0xFFF5F7F8);
  static const Color textDark = Color(0xFF24413D);
  static const Color textGrey = Color(0xFF7B8A89);

  @override
  State<PetugasDashboard> createState() => _PetugasDashboardState();
}

class _PetugasDashboardState extends State<PetugasDashboard> {
  // ============================================================
  // DATA DASHBOARD
  // ============================================================

  bool isLoading = true;
  bool isLoadingAktivitas = true;

  int totalNasabah = 0;
  int setoranHariIni = 0;
  int totalPending = 0;

  double kasBankSampah = 0;
  double totalSaldoNasabah = 0;
  double totalSampah = 0;

  List<dynamic> aktivitasTerbaru = [];
  List<dynamic> dataSetoran7Hari = [];
  List<dynamic> dataKomposisiSampah = [];

  DateTime _bulanKomposisi = DateTime.now();

  // ============================================================
  // HELPER FORMAT DATA
  // ============================================================

  String _formatBulanApi(DateTime tanggal) {
    return '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}';
  }

  String _namaBulan(int bulan) {
    const daftarBulan = [
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

    return daftarBulan[bulan - 1];
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // FORMAT ANGKA
  // ============================================================

  String _formatAngka(num value) {
    final angka = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < angka.length; i++) {
      if (i > 0 && (angka.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(angka[i]);
    }

    return buffer.toString();
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String formatRupiah(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp${buffer.toString()}';
  }

  // ============================================================
  // LOAD DATA DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final data = await ApiService.getPetugasDashboard(
        bulan: _formatBulanApi(_bulanKomposisi),
      );

      if (!mounted) return;

      setState(() {
        totalNasabah = _toInt(data['total_nasabah']);

        kasBankSampah = _toDouble(data['kas_bank_sampah']);

        totalSaldoNasabah = _toDouble(data['total_saldo_nasabah']);

        setoranHariIni = _toInt(data['setoran_hari_ini']);

        totalSampah = _toDouble(data['berat_sampah_hari_ini']) * 1000;

        totalPending = _toInt(data['total_pending']);

        dataSetoran7Hari = List<dynamic>.from(data['setoran_7_hari'] ?? []);

        dataKomposisiSampah = List<dynamic>.from(
          data['komposisi_sampah'] ?? [],
        );

        isLoading = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD PETUGAS ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data dashboard.')),
      );
    }
  }

  // ============================================================
  // LOAD AKTIVITAS TERBARU
  // ============================================================

  Future<void> _loadAktivitas() async {
    try {
      final sekarang = DateTime.now();

      final halamanSetoran = await ApiService.getPetugasSetoranPage(
        bulan: sekarang.month,
        tahun: sekarang.year,
        page: 1,
        perPage: 20,
      );

      final hasilSetoran = halamanSetoran.items;

      final List<Map<String, dynamic>> data = [];

      for (final item in hasilSetoran) {
        data.add({
          'nama': item.namaNasabah,
          'jenis': 'Setoran',
          'detail': '${item.namaSampah} • ${item.totalBerat} kg',
          'nominal': item.totalNilai,
          'tanggal': DateTime.tryParse(item.tanggal) ?? DateTime(2000),
          'icon': Icons.recycling_rounded,
          'warna': PetugasDashboard.primaryGreen,
        });
      }

      // Urutkan dari transaksi terbaru
      data.sort((a, b) {
        return (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime);
      });

      if (!mounted) return;

      setState(() {
        aktivitasTerbaru = data.take(5).toList();
        isLoadingAktivitas = false;
      });
    } catch (e) {
      debugPrint('AKTIVITAS TERBARU ERROR: $e');

      if (!mounted) return;

      setState(() {
        aktivitasTerbaru = [];
        isLoadingAktivitas = false;
      });
    }
  }

  // ============================================================
  // LOAD KOMPOSISI SAMPAH
  // ============================================================

  Future<void> _loadKomposisiSampah() async {
    try {
      final data = await ApiService.getPetugasDashboard(
        bulan: _formatBulanApi(_bulanKomposisi),
      );

      if (!mounted) return;

      setState(() {
        dataKomposisiSampah = List<dynamic>.from(
          data['komposisi_sampah'] ?? [],
        );
      });
    } catch (e) {
      debugPrint('KOMPOSISI SAMPAH ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui komposisi jenis sampah.'),
        ),
      );
    }
  }

  // ============================================================
  // HEADER DASHBOARD
  // ============================================================

  Widget _buildDashboardHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Petugas',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Ringkasan aktivitas Bank Sampah Griya Ayu',
          style: TextStyle(color: PetugasDashboard.darkGreen, fontSize: 12),
        ),
      ],
    );
  }

  // ============================================================
  // JUDUL SECTION
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: PetugasDashboard.textDark,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ============================================================
  // STATISTIK DASHBOARD
  // ============================================================

  Widget _buildStatistics() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _statisticCard(
          title: 'Kas Bank Sampah',
          value: isLoading ? '...' : formatRupiah(kasBankSampah),
          icon: Icons.account_balance_outlined,
        ),

        _statisticCard(
          title: 'Total Saldo Nasabah',
          value: isLoading ? '...' : formatRupiah(totalSaldoNasabah),
          icon: Icons.account_balance_wallet_outlined,
        ),

        _statisticCard(
          title: 'Total Nasabah',
          value: isLoading ? '...' : '$totalNasabah',
          icon: Icons.people_outline_rounded,
        ),

        _statisticCard(
          title: 'Setoran Hari Ini',
          value: isLoading ? '...' : '$setoranHariIni',
          icon: Icons.inventory_2_outlined,
        ),

        _statisticCard(
          title: 'Sampah Terkumpul Hari Ini',
          value: isLoading ? '...' : '${_formatAngka(totalSampah)} gram',
          icon: Icons.recycling_rounded,
        ),

        _statisticCard(
          title: 'Penarikan Pending',
          value: isLoading ? '...' : '$totalPending',
          icon: Icons.pending_actions_outlined,
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIC CARD
  // ============================================================

  Widget _statisticCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: PetugasDashboard.primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: PetugasDashboard.primaryGreen,
                  size: 19,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.more_horiz_rounded,
                color: Colors.grey,
                size: 18,
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PetugasDashboard.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PetugasDashboard.textGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRAFIK DASHBOARD
  // ============================================================

  Widget _buildDashboardCharts() {
    final valuesSetoran = dataSetoran7Hari.map<double>((item) {
      return _toDouble(item['total_berat']);
    }).toList();

    final labelsSetoran = dataSetoran7Hari.map<String>((item) {
      final tanggal = DateTime.tryParse(item['tanggal']?.toString() ?? '');

      if (tanggal == null) return '-';

      return '${tanggal.day} ${_namaBulan(tanggal.month).substring(0, 3)}';
    }).toList();

    final valuesKomposisi = dataKomposisiSampah.map<double>((item) {
      return _toDouble(item['total_berat']);
    }).toList();

    final labelsKomposisi = dataKomposisiSampah.map<String>((item) {
      return item['nama_sampah']?.toString() ?? 'Lainnya';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lineChartCard(
          title: 'Setoran Sampah 7 Hari Terakhir',
          subtitle: 'Total berat sampah (kg)',
          values: valuesSetoran,
          labels: labelsSetoran,
        ),

        const SizedBox(height: 16),

        _horizontalChartCard(
          title: 'Komposisi Jenis Sampah',
          subtitle: 'Berat berdasarkan jenis sampah (kg)',
          values: valuesKomposisi,
          labels: labelsKomposisi,
          headerAction: InkWell(
            onTap: _pilihBulanKomposisi,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDCE5E2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_namaBulan(_bulanKomposisi.month)} '
                    '${_bulanKomposisi.year}',
                    style: const TextStyle(
                      color: PetugasDashboard.darkGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: PetugasDashboard.darkGreen,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHART CARD
  // ============================================================

  Widget _lineChartCard({
    required String title,
    required String subtitle,
    required List<double> values,
    required List<String> labels,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PetugasDashboard.textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: PetugasDashboard.textDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            width: double.infinity,
            child: values.isEmpty || !values.any((v) => v > 0)
                ? const Center(
                    child: Text(
                      'Belum ada data pada periode ini.',
                      style: TextStyle(
                        color: PetugasDashboard.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _LineChartPainter(values: values, labels: labels),
                    child: const SizedBox.expand(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _horizontalChartCard({
    required String title,
    required String subtitle,
    required List<double> values,
    required List<String> labels,
    Widget? headerAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PetugasDashboard.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: PetugasDashboard.textDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          if (values.isEmpty || !values.any((v) => v > 0))
            const SizedBox(
              height: 130,
              child: Center(
                child: Text(
                  'Belum ada data pada periode ini.',
                  style: TextStyle(
                    color: PetugasDashboard.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: (values.length * 43 + 30).toDouble() < 250
                        ? 250
                        : (values.length * 43 + 30).toDouble(),
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _HorizontalChartPainter(
                        values: values,
                        labels: labels,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PILIH BULAN KOMPOSISI SAMPAH
  // ============================================================

  Future<void> _pilihBulanKomposisi() async {
    int bulanDipilih = _bulanKomposisi.month;
    int tahunDipilih = _bulanKomposisi.year;

    final sekarang = DateTime.now();

    final hasil = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Pilih Bulan dan Tahun',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: PetugasDashboard.darkGreen,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: bulanDipilih,
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(_namaBulan(index + 1)),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          bulanDipilih = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<int>(
                    value: tahunDipilih,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(sekarang.year - 2020 + 1, (index) {
                      final tahun = sekarang.year - index;

                      return DropdownMenuItem(
                        value: tahun,
                        child: Text('$tahun'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          tahunDipilih = value;

                          if (tahunDipilih == sekarang.year &&
                              bulanDipilih > sekarang.month) {
                            bulanDipilih = sekarang.month;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: PetugasDashboard.textGrey),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PetugasDashboard.darkGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      DateTime(tahunDipilih, bulanDipilih),
                    );
                  },
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
      },
    );

    if (hasil == null || !mounted) return;

    if (hasil.year == _bulanKomposisi.year &&
        hasil.month == _bulanKomposisi.month) {
      return;
    }

    setState(() {
      _bulanKomposisi = hasil;
    });

    await _loadKomposisiSampah();
  }

  // ============================================================
  // TRANSAKSI TERBARU
  // ============================================================

  Widget _buildLatestTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transaksi Setoran Terbaru',
                  style: TextStyle(
                    color: PetugasDashboard.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  widget.onMenuSelected('riwayat');
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: PetugasDashboard.darkGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (isLoadingAktivitas)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: CircularProgressIndicator(
                  color: PetugasDashboard.darkGreen,
                ),
              ),
            )
          else if (aktivitasTerbaru.isEmpty)
            const Padding(
              padding: EdgeInsets.all(15),
              child: Center(
                child: Text(
                  'Belum ada transaksi.',
                  style: TextStyle(
                    color: PetugasDashboard.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            ...aktivitasTerbaru.map((item) {
              return _transactionItem(Map<String, dynamic>.from(item));
            }),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSAKSI ITEM
  // ============================================================

  Widget _transactionItem(Map<String, dynamic> item) {
    final nominal = _toDouble(item['nominal']);
    final tanggal = item['tanggal'] as DateTime;

    final tanggalFormat =
        '${tanggal.day.toString().padLeft(2, '0')}/'
        '${tanggal.month.toString().padLeft(2, '0')}/'
        '${tanggal.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PetugasDashboard.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.recycling_outlined,
              color: PetugasDashboard.primaryGreen,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama']?.toString() ?? '-',
                  style: const TextStyle(
                    color: PetugasDashboard.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  item['detail']?.toString() ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PetugasDashboard.textGrey,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  tanggalFormat,
                  style: const TextStyle(
                    color: PetugasDashboard.textGrey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(nominal),
                style: const TextStyle(
                  color: PetugasDashboard.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Setoran',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboard();
    _loadAktivitas();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PetugasDashboard.background,
      child: RefreshIndicator(
        color: PetugasDashboard.darkGreen,
        onRefresh: () async {
          await Future.wait([_loadDashboard(), _loadAktivitas()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER DASHBOARD
              // ==================================================

              _buildDashboardHeader(),

              const SizedBox(height: 18),

              // ==================================================
              // STATISTIK
              // ==================================================
              _buildStatistics(),

              const SizedBox(height: 22),

              // ==================================================
              // GRAFIK
              // ==================================================
              _buildDashboardCharts(),

              const SizedBox(height: 22),

              // ==================================================
              // TRANSAKSI TERBARU
              // ==================================================
              _buildLatestTransactions(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _LineChartPainter({required this.values, required this.labels});

  static const Color green = Color(0xFF2E8B72);
  static const Color grey = Color(0xFF7B8A89);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const left = 32.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 27.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final maximum = values.reduce((a, b) => a > b ? a : b);
    final maxValue = maximum <= 0 ? 1.0 : maximum * 1.2;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8ECEA)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = green
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = green.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? left + chartWidth / 2
          : left + (chartWidth * i / (values.length - 1));

      final y = top + chartHeight - (values[i] / maxValue * chartHeight);

      points.add(Offset(x, y));
    }

    // Garis grid dan label sumbu Y
    for (int i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      final angka = (maxValue * (4 - i) / 4).toStringAsFixed(1);

      final text = TextPainter(
        text: TextSpan(
          text: angka,
          style: const TextStyle(color: grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      text.paint(canvas, Offset(left - text.width - 5, y - text.height / 2));
    }

    // Area di bawah garis
    if (points.length >= 2) {
      final fillPath = Path()..moveTo(points.first.dx, top + chartHeight);

      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      fillPath
        ..lineTo(points.last.dx, top + chartHeight)
        ..close();

      canvas.drawPath(fillPath, fillPaint);
    }

    // Garis grafik
    if (points.length >= 2) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(linePath, linePaint);
    }

    // Titik data dan label tanggal
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.5, Paint()..color = green);

      canvas.drawCircle(points[i], 1.7, Paint()..color = Colors.white);

      final label = i < labels.length ? labels[i] : '-';

      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: chartWidth / values.length + 10);

      text.paint(
        canvas,
        Offset(points[i].dx - text.width / 2, top + chartHeight + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

// ============================================================
// HORIZONTAL BAR CHART
// ============================================================

class _HorizontalChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _HorizontalChartPainter({required this.values, required this.labels});

  static const Color green = Color(0xFF2E8B72);
  static const Color grey = Color(0xFF7B8A89);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const left = 85.0;
    const right = 8.0;
    const top = 5.0;
    const bottom = 22.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final maximum = values.reduce((a, b) => a > b ? a : b);
    final maxValue = maximum <= 0 ? 1.0 : maximum * 1.15;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8ECEA)
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = green
      ..style = PaintingStyle.fill;

    // Grid dan label sumbu X
    const jumlahGrid = 4;

    for (int i = 0; i <= jumlahGrid; i++) {
      final x = left + chartWidth * i / jumlahGrid;

      canvas.drawLine(Offset(x, top), Offset(x, top + chartHeight), gridPaint);

      final angka = (maxValue * i / jumlahGrid).toStringAsFixed(1);

      final text = TextPainter(
        text: TextSpan(
          text: angka,
          style: const TextStyle(color: grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      text.paint(canvas, Offset(x - text.width / 2, top + chartHeight + 5));
    }

    final rowHeight = chartHeight / values.length;
    final barHeight = rowHeight * 0.48;

    for (int i = 0; i < values.length; i++) {
      final centerY = top + rowHeight * (i + 0.5);

      final label = i < labels.length ? labels[i] : '-';

      final labelText = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: left - 10);

      labelText.paint(
        canvas,
        Offset(left - labelText.width - 10, centerY - labelText.height / 2),
      );

      final barWidth = values[i] / maxValue * chartWidth;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, centerY - barHeight / 2, barWidth, barHeight),
        const Radius.circular(8),
      );

      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

// ============================================================
// ALIAS PETUGAS DASHBOARD
// ============================================================

class PetugasDashboardScreen extends StatelessWidget {
  const PetugasDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PetugasDashboard(onMenuSelected: (menu) {});
  }
}

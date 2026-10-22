import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../services/api_service.dart';
import 'login_keamanan_screen.dart';

class ProfilScreen extends StatefulWidget {
  final int idNasabah;

  const ProfilScreen({super.key, required this.idNasabah});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? profil;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final hasil = await ApiService.getProfilNasabah(widget.idNasabah);

      if (!mounted) return;

      setState(() {
        profil = hasil;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _editProfil() async {
    final namaController = TextEditingController(
      text: _getValue('nama_lengkap', fallback: ''),
    );
    final emailController = TextEditingController(
      text: _getValue('email', fallback: ''),
    );
    final teleponController = TextEditingController(
      text: _getValue('no_telepon', fallback: ''),
    );

    bool menyimpan = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  const Expanded(
                    child: Text('Edit Profil', style: TextStyle(fontSize: 16)),
                  ),
                  IconButton(
                    onPressed: menyimpan
                        ? null
                        : () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, size: 19),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldEdit('Nama Lengkap', namaController),
                    const SizedBox(height: 12),
                    _fieldEdit(
                      'Email',
                      emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _fieldEdit(
                      'Nomor HP',
                      teleponController,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: menyimpan
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: menyimpan
                            ? null
                            : () async {
                                final nama = namaController.text.trim();
                                final email = emailController.text.trim();
                                final telepon = teleponController.text.trim();

                                if (nama.isEmpty ||
                                    email.isEmpty ||
                                    telepon.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Semua kolom wajib diisi.'),
                                    ),
                                  );
                                  return;
                                }

                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Format email tidak valid.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  menyimpan = true;
                                });

                                try {
                                  await ApiService.updateProfilNasabah(
                                    idNasabah: widget.idNasabah,
                                    namaLengkap: nama,
                                    email: email,
                                    noTelepon: telepon,
                                  );

                                  if (!mounted) return;

                                  Navigator.pop(dialogContext);
                                  await _loadProfil();

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profil berhasil diperbarui.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  setDialogState(() {
                                    menyimpan = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: menyimpan
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    namaController.dispose();
    emailController.dispose();
    teleponController.dispose();
  }

  Widget _fieldEdit(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
      ],
    );
  }

  String _formatRupiah(dynamic value) {
    final saldo = double.tryParse(value?.toString() ?? '') ?? 0;
    final angka = saldo.toInt().toString();

    final hasil = angka.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp$hasil';
  }

  String _formatBerat(dynamic value) {
    final berat = double.tryParse(value?.toString() ?? '') ?? 0;

    final angka = berat == berat.truncateToDouble()
        ? berat.toStringAsFixed(0)
        : berat
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');

    return '$angka kg';
  }

  String _getValue(String key, {String fallback = '-'}) {
    final value = profil?[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  String _getStatus() {
    return _getValue('status', fallback: 'Tidak diketahui');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Profil Nasabah',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfil,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (profil == null) {
      return const Center(child: Text('Data profil tidak tersedia.'));
    }

    final nama = _getValue('nama_lengkap', fallback: 'Nasabah');
    final email = _getValue('email');
    final telepon = _getValue('no_telepon');
    final status = _getStatus();

    final nomorAnggota = 'BSA-${widget.idNasabah.toString().padLeft(4, '0')}';

    return RefreshIndicator(
      onRefresh: _loadProfil,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          // KARTU PROFIL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EBEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2FCB78),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : 'N',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1679B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [_badgeProfil(nomorAnggota), _badgeProfil(status)],
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: _editProfil,
                  icon: const Icon(Icons.edit_outlined, size: 12),
                  label: const Text(
                    'Edit Profil',
                    style: TextStyle(fontSize: 10),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF20A85A),
                    side: const BorderSide(color: Color(0xFF2FCB78)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // INFORMASI AKUN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EBEE)),
            ),
            child: Column(
              children: [
                _barisProfil(
                  Icons.shield_outlined,
                  'Nomor Anggota',
                  nomorAnggota,
                ),
                _pemisahProfil(),
                _barisProfil(Icons.person_outline, 'Nama Lengkap', nama),
                _pemisahProfil(),
                _barisProfil(Icons.email_outlined, 'Email', email),
                _pemisahProfil(),
                _barisProfil(Icons.phone_outlined, 'Nomor HP', telepon),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LOGIN DAN KEAMANAN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EBEE)),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.lock_outline,
                size: 18,
                color: AppColors.primary,
              ),
              title: const Text(
                'Login dan Keamanan',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                size: 17,
                color: Colors.grey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LoginKeamananScreen(idNasabah: widget.idNasabah),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // KELUAR AKUN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EBEE)),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.logout,
                size: 17,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Keluar dari Akun',
                style: TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Hubungkan menu ini ke proses logout aplikasi.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeProfil(String teks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 8, color: Color(0xFF16894A)),
      ),
    );
  }

  Widget _barisProfil(IconData ikon, String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 14, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF9299A3)),
                ),
                const SizedBox(height: 2),
                Text(
                  nilai,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF344054),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pemisahProfil() {
    return const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F1F3));
  }

  // INFO ITEM
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STATISTIC CARD
  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

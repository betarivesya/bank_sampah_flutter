import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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
  bool _sedangMemilihFoto = false;

  String? errorMessage;
  File? _fotoSementara;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _loadProfil();

    // Memulihkan hasil pemilihan foto jika Android
    // menutup Activity aplikasi saat galeri dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pulihkanFotoHilang();
    });
  }

  // =========================================================
  // MEMUAT PROFIL
  // =========================================================

  Future<void> _loadProfil() async {
    if (!mounted) return;

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

  // =========================================================
  // MEMILIH FOTO
  // =========================================================

  Future<void> _pilihFoto(ImageSource source) async {
    if (_sedangMemilihFoto || !mounted) return;

    setState(() {
      _sedangMemilihFoto = true;
    });

    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (foto == null || !mounted) return;

      await _prosesFoto(foto);
    } on PlatformException catch (e, stackTrace) {
      debugPrint('IMAGE PICKER ERROR: ${e.code} - ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      _tampilkanPesan('Gagal memilih foto: ${e.message ?? e.code}');
    } catch (e, stackTrace) {
      debugPrint('PILIH FOTO ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      _tampilkanPesan('Gagal memproses foto. Silakan coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          _sedangMemilihFoto = false;
        });
      }
    }
  }

  // =========================================================
  // CROP FOTO
  // =========================================================

  Future<void> _prosesFoto(XFile foto) async {
    if (!mounted) return;

    final CroppedFile? hasilCrop = await ImageCropper().cropImage(
      sourcePath: foto.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Atur Foto Profil',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Atur Foto Profil',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (!mounted || hasilCrop == null) return;

    final File fileFoto = File(hasilCrop.path);

    if (!await fileFoto.exists()) {
      _tampilkanPesan('File foto tidak ditemukan.');
      return;
    }

    if (await fileFoto.length() == 0) {
      _tampilkanPesan('File foto kosong. Silakan pilih foto lain.');
      return;
    }

    // Tampilkan hasil crop sebelum upload selesai.
    setState(() {
      _fotoSementara = fileFoto;
    });

    await _uploadFotoHasilCrop(fileFoto);
  }

  // =========================================================
  // UPLOAD FOTO KE API
  // =========================================================

  Future<void> _uploadFotoHasilCrop(File foto) async {
    if (!mounted) return;

    try {
      await ApiService.uploadFotoProfilNasabah(
        idNasabah: widget.idNasabah,
        foto: foto,
      );

      if (!mounted) return;

      // Muat kembali data agar URL foto dari server digunakan.
      await _loadProfil();

      if (!mounted) return;

      _tampilkanPesan('Foto profil berhasil diperbarui.');
    } catch (e, stackTrace) {
      debugPrint('UPLOAD FOTO ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _tampilkanPesan(
        'Gagal mengunggah foto: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // =========================================================
  // PEMULIHAN FOTO YANG HILANG DI ANDROID
  // =========================================================

  Future<void> _pulihkanFotoHilang() async {
    if (!mounted || _sedangMemilihFoto) return;

    try {
      final hasilPicker = await _imagePicker.retrieveLostData();

      if (!mounted) return;

      final files = hasilPicker.files;

      if (files != null && files.isNotEmpty) {
        setState(() {
          _sedangMemilihFoto = true;
        });

        try {
          await _prosesFoto(files.first);
        } finally {
          if (mounted) {
            setState(() {
              _sedangMemilihFoto = false;
            });
          }
        }

        return;
      }

      if (hasilPicker.exception != null) {
        debugPrint('GAGAL MEMULIHKAN PICKER: ${hasilPicker.exception}');
      }

      // Jika hasil crop sebelumnya hilang, coba pulihkan.
      final CroppedFile? hasilCrop = await ImageCropper().recoverImage();

      if (!mounted || hasilCrop == null) return;

      setState(() {
        _sedangMemilihFoto = true;
        _fotoSementara = File(hasilCrop.path);
      });

      try {
        await _uploadFotoHasilCrop(File(hasilCrop.path));
      } finally {
        if (mounted) {
          setState(() {
            _sedangMemilihFoto = false;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('PEMULIHAN FOTO ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // =========================================================
  // FOTO PROFIL: PREVIEW, PILIH SUMBER, DAN HAPUS
  // =========================================================

  bool get _memilikiFotoProfil {
    final url = profil?['foto_profil_url']?.toString();
    return _fotoSementara != null || (url != null && url.trim().isNotEmpty);
  }

  ImageProvider? _sumberFotoProfil() {
    if (_fotoSementara != null) return FileImage(_fotoSementara!);

    final url = profil?['foto_profil_url']?.toString();
    if (url != null && url.trim().isNotEmpty) return NetworkImage(url);
    return null;
  }

  void _tampilkanFotoBesar() {
    final sumberFoto = _sumberFotoProfil();
    if (sumberFoto == null) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: sumberFoto,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: Text(
                        'Foto profil tidak dapat ditampilkan.',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tampilkanPilihanFoto() async {
    if (_sedangMemilihFoto || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DEE3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Foto Profil',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    if (_memilikiFotoProfil)
                      IconButton(
                        tooltip: 'Hapus foto profil',
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _konfirmasiHapusFoto();
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih sumber foto yang ingin digunakan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _ikonSumberFoto(Icons.camera_alt_outlined),
                  title: const Text(
                    'Ambil Foto',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Gunakan kamera HP',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pilihFoto(ImageSource.camera);
                  },
                ),

                const Divider(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _ikonSumberFoto(Icons.photo_library_outlined),
                  title: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Pilih foto yang tersimpan di HP',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pilihFoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _konfirmasiHapusFoto() async {
    if (!_memilikiFotoProfil || !mounted) return;

    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Foto Profil?'),
        content: const Text(
          'Foto profil akan dihapus dan avatar akan kembali ke inisial nama. '
          'Kamu yakin ingin melanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin != true || !mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.hapusFotoProfilNasabah(idNasabah: widget.idNasabah);

      if (!mounted) return;
      setState(() {
        profil?['foto_profil'] = null;
        profil?['foto_profil_url'] = null;
        _fotoSementara = null;
        isLoading = false;
      });

      await _loadProfil();
      if (!mounted) return;
      _tampilkanPesan('Foto profil berhasil dihapus.');
    } catch (e, stackTrace) {
      debugPrint('HAPUS FOTO ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _tampilkanPesan(
        'Gagal menghapus foto: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Widget _ikonSumberFoto(IconData ikon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(ikon, color: const Color(0xFF167A63)),
    );
  }

  // =========================================================
  // EDIT PROFIL
  // =========================================================

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

    try {
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
                      child: Text(
                        'Edit Profil',
                        style: TextStyle(fontSize: 16),
                      ),
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
                                    _tampilkanPesan('Semua kolom wajib diisi.');
                                    return;
                                  }

                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(email)) {
                                    _tampilkanPesan(
                                      'Format email tidak valid.',
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

                                    _tampilkanPesan(
                                      'Profil berhasil diperbarui.',
                                    );
                                  } catch (e) {
                                    setDialogState(() {
                                      menyimpan = false;
                                    });

                                    _tampilkanPesan(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
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
    } finally {
      namaController.dispose();
      emailController.dispose();
      teleponController.dispose();
    }
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

  // =========================================================
  // FOTO PROFIL
  // =========================================================

  Widget _buildFotoProfil(String nama) {
    // Prioritaskan foto lokal yang baru dipilih.
    if (_fotoSementara != null) {
      return Container(
        width: 76,
        height: 76,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Color(0xFF2FCB78),
          shape: BoxShape.circle,
        ),
        child: Image.file(
          _fotoSementara!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _inisialProfil(nama);
          },
        ),
      );
    }

    final url = profil?['foto_profil_url']?.toString();

    return Container(
      width: 76,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFF2FCB78),
        shape: BoxShape.circle,
      ),
      child: url != null && url.trim().isNotEmpty
          ? Image.network(
              url,
              key: ValueKey(url),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _inisialProfil(nama);
              },
            )
          : _inisialProfil(nama),
    );
  }

  Widget _inisialProfil(String nama) {
    return Center(
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'N',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // =========================================================
  // FORMAT DATA
  // =========================================================

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

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // =========================================================
  // BUILD
  // =========================================================

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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _memilikiFotoProfil ? _tampilkanFotoBesar : null,
                      child: _buildFotoProfil(nama),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: const Color(0xFF167A63),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _sedangMemilihFoto
                              ? null
                              : _tampilkanPilihanFoto,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 27,
                            height: 27,
                            child: Center(
                              child: _sedangMemilihFoto
                                  ? const SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 5,
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
            child: Material(
              color: Colors.transparent,
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
          ),

          const SizedBox(height: 10),

          // KELUAR AKUN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EBEE)),
            ),
            child: Material(
              color: Colors.transparent,
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
                  _tampilkanPesan(
                    'Hubungkan menu ini ke proses logout aplikasi.',
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KOMPONEN TAMPILAN
  // =========================================================

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

  // Komponen tambahan yang dipertahankan.
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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../widgets/google_sign_in_button.dart';

import '../../services/api_service.dart';

import 'lupa_password_screen.dart';
import 'register_screen.dart';
import '../admin/admin_layout.dart';
import '../petugas/petugas_layout.dart';
import '../nasabah/nasabah_dashboard.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final PageController _bannerController = PageController();
  static Future<void>? _inisialisasiGoogle;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;

  int _currentBanner = 0;
  bool obscurePassword = true;
  bool _googleSiap = false;
  bool _sedangLoginGoogle = false;

  final List<_BannerItem> _bannerItems = const [
    _BannerItem(
      title: 'Bank Sampah',
      subtitle: 'Kelola sampah jadi nilai ekonomis',
      asset: 'assets/images/sampahtumbuhan.jpg',
    ),
    _BannerItem(
      title: 'Transaksi Cepat',
      subtitle: 'Pantau setoran dan penarikan saldo dengan mudah',
      asset: 'assets/images/sampahtumbuhan.jpg',
    ),
    _BannerItem(
      title: 'Lingkungan Lebih Baik',
      subtitle: 'Setiap sampah yang dipilah memberi manfaat besar',
      asset: 'assets/images/sampahtumbuhan.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bannerController.addListener(() {
      final currentPage = (_bannerController.page ?? 0).round();

      if (currentPage != _currentBanner && mounted) {
        setState(() {
          _currentBanner = currentPage;
        });
      }
    });

    _siapkanGoogleSignIn();
  }

  Future<void> _siapkanGoogleSignIn() async {
    try {
      _inisialisasiGoogle ??= GoogleSignIn.instance.initialize(
        serverClientId: '722255836789-buln8chd8i3mrrig03ht252qnelt2js8.apps.googleusercontent.com',
      );

      await _inisialisasiGoogle!.timeout(const Duration(seconds: 10));

      if (!mounted) return;

      await _googleSubscription?.cancel();

      _googleSubscription = GoogleSignIn.instance.authenticationEvents.listen(
        _tanganiEventGoogle,
        onError: _tanganiErrorGoogle,
      );

      setState(() {
        _googleSiap = true;
      });
    } on TimeoutException {
      debugPrint('Google Sign-In timeout saat inisialisasi.');

      if (mounted) {
        setState(() {
          _googleSiap = false;
        });

        _tampilkanPesan(
          'Google Sign-In terlalu lama disiapkan. Silakan muat ulang aplikasi.',
        );
      }
    } catch (e) {
      debugPrint('Inisialisasi Google Sign-In gagal: $e');

      if (mounted) {
        setState(() {
          _googleSiap = false;
        });

        _tampilkanPesan(
          'Google Sign-In gagal disiapkan. Silakan muat ulang halaman.',
        );
      }
    }
  }

  Future<void> _tanganiEventGoogle(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) {
      return;
    }

    final idToken = event.user.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      _tampilkanPesan('Google tidak memberikan ID Token.');
      return;
    }

    await _prosesLoginGoogle(idToken);
  }

  void _tanganiErrorGoogle(Object error) {
    debugPrint('Google Sign-In error: $error');

    if (!mounted || _sedangLoginGoogle) return;

    _tampilkanPesan(
      error is GoogleSignInException &&
              error.code == GoogleSignInExceptionCode.canceled
          ? 'Login Google dibatalkan.'
          : 'Login Google gagal. Periksa konfigurasi Google Sign-In.',
    );
  }

  Future<void> _loginGoogleAndroid() async {
    if (!_googleSiap || _sedangLoginGoogle) return;

    try {
      await GoogleSignIn.instance.authenticate();
      // Hasil login ditangani melalui authenticationEvents.
    } catch (e) {
      debugPrint('Gagal memulai login Google: $e');

      if (mounted) {
        _tampilkanPesan('Tidak dapat memulai login Google.');
      }
    }
  }

  Future<void> _prosesLoginGoogle(String idToken) async {
    if (_sedangLoginGoogle) return;

    setState(() {
      _sedangLoginGoogle = true;
    });

    try {
      final result = await ApiService.loginGoogle(idToken);

      if (!mounted) return;

      if (result['success'] != true) {
        _tampilkanPesan(result['message']?.toString() ?? 'Login Google gagal.');
        return;
      }

      final user = result['user'];

      if (user is! Map) {
        _tampilkanPesan('Data pengguna tidak ditemukan.');
        return;
      }

      await _arahKeDashboard(Map<String, dynamic>.from(user));
    } catch (e) {
      debugPrint('Proses login Google gagal: $e');

      if (mounted) {
        _tampilkanPesan('Terjadi kesalahan saat login Google.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _sedangLoginGoogle = false;
        });
      }
    }
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _tampilkanPesan('Email dan password harus diisi.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final result = await ApiService.login(username, password);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (result['success'] != true) {
        _tampilkanPesan(result['message']?.toString() ?? 'Login gagal.');
        return;
      }

      final user = result['user'];

      if (user is! Map) {
        _tampilkanPesan('Data pengguna tidak ditemukan.');
        return;
      }

      await _arahKeDashboard(Map<String, dynamic>.from(user));
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      debugPrint('Login biasa gagal: $e');
      _tampilkanPesan('Terjadi kesalahan saat login.');
    }
  }

  Future<void> _arahKeDashboard(Map<String, dynamic> user) async {
    if (!mounted) return;

    final role = user['role']?.toString().toLowerCase();

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLayout()),
      );
    } else if (role == 'petugas') {
      final idPetugas = int.tryParse(
        (user['id'] ?? user['id_pengguna'] ?? user['id_petugas'] ?? '')
            .toString(),
      );

      if (idPetugas == null) {
        _tampilkanPesan('ID petugas tidak ditemukan dari respons login.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PetugasLayout(idPetugas: idPetugas),
        ),
      );
    } else if (role == 'nasabah') {
      final idNasabah = int.tryParse((user['id_nasabah'] ?? '').toString());

      if (idNasabah == null) {
        _tampilkanPesan('Profil nasabah tidak ditemukan.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NasabahDashboard(idNasabah: idNasabah),
        ),
      );
    } else {
      _tampilkanPesan('Role pengguna tidak dikenali.');
    }
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    usernameController.dispose();
    passwordController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER / BANNER
              SizedBox(
                height: 230,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: _bannerItems.length,
                        itemBuilder: (context, index) {
                          final banner = _bannerItems[index];

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(banner.asset, fit: BoxFit.cover),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFF153834)
                                            .withValues(alpha: 0.25),
                                        const Color(0xFF153834)
                                            .withValues(alpha: 0.8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      height: 75,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.recycling,
                                        size: 45,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      banner.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      banner.subtitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _bannerItems.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: _currentBanner == index ? 18 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentBanner == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // FORM LOGIN
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17332E),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Silahkan masuk untuk melanjutkan.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF71847F)),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan username atau nomor anggota',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // PEMISAH LOGIN GOOGLE
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau masuk dengan',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // GOOGLE SIGN-IN
                    Center(
                      child: _sedangLoginGoogle
                          ? const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Sedang login dengan Google...'),
                              ],
                            )
                          : !_googleSiap
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Menyiapkan Google Sign-In...'),
                              ],
                            )
                          : kIsWeb
                          ? buildGoogleSignInButton()
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _loginGoogleAndroid,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFDADCE0)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: SvgPicture.string(
                                  r'''
                                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
                                    <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
                                    <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.73 7.18l7.65 5.94c4.46-4.13 7.12-10.2 7.12-17.59z"/>
                                    <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-3-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24s.92 7.54 2.56 10.78l7.97-6.19z"/>
                                    <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.91-5.81l-7.65-5.94c-2.13 1.43-4.89 2.27-8.26 2.27-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
                                  </svg>
                                  ''',
                                  width: 22,
                                  height: 22,
                                ),
                                label: const Text('Masuk dengan Google'),
                              ),
                            ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LupaPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(color: Color(0xFF2D6A4F)),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF2D6A4F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Center(
                      child: Text(
                        'Bank Sampah Griya Ayu',
                        style: TextStyle(
                          color: Color(0xFF71847F),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerItem {
  final String title;
  final String subtitle;
  final String asset;

  const _BannerItem({
    required this.title,
    required this.subtitle,
    required this.asset,
  });
}

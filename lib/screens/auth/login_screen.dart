import 'package:flutter/material.dart';

import 'lupa_password_screen.dart';
import 'register_screen.dart';
import '../admin/admin_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final PageController _bannerController = PageController();

  int _currentBanner = 0;
  bool obscurePassword = true;

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

      if (currentPage != _currentBanner) {
        setState(() {
          _currentBanner = currentPage;
        });
      }
    });
  }

  @override
  void dispose() {
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
              // =========================
              // HEADER / BANNER
              // =========================
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
                              Positioned.fill(
                                child: Image.asset(
                                  banner.asset,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFF164A43)
                                            .withValues(alpha: 0.25),
                                        const Color(0xFF164A43)
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

                    // =========================
                    // INDICATOR
                    // =========================
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

              // =========================
              // FORM LOGIN
              // =========================
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
                        color: Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Silahkan masuk untuk melanjutkan.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Username / Nomor Anggota',
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

                    // =========================
                    // TOMBOL MASUK
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminLayout(),
                            ),
                          );
                        },
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
                            style: TextStyle(color: Color(0xFF159447)),
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
                              color: Color(0xFF159447),
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
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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

import 'package:flutter/material.dart';

import 'auth/login_screen.dart';

/// Tampilan logo saat aplikasi pertama dibuka (splash screen).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Pengendali animasi
  late final AnimationController _controller;

  // Animasi logo dari transparan menjadi jelas
  late final Animation<double> _fade;

  // Animasi logo dari agak kecil menjadi ukuran normal
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Animasi berlangsung 1,2 detik
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Efek fade-in
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Efek membesar dari 85% ke 100%
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Jalankan animasi
    _controller.forward();

    // Mulai hitung mundur untuk pindah ke halaman login
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    // Lama splash screen tampil 3 detik
    await Future.delayed(const Duration(seconds: 3));


    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/images/logo-griya-ayu.png',
              width: width * 0.45,
              height: width * 0.45,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

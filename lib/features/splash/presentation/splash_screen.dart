import 'package:flutter/material.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigasi otomatis setelah beberapa detik (Simulasi Splash Screen)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Navigasi ke Onboarding Screen
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Caduceus (Gaya HaloDoc)
            const Icon(
              Icons.local_hospital, // Ganti dengan Icon Caduceus jika ada
              size: 100,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 20),
            // Nama Aplikasi
            Text(
              'Arsawan', // Ganti dengan nama aplikasi Anda
              style: AppStyles.headline1.copyWith(
                color: AppColors.primaryBlue,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 50),
            // Tombol Swipe ala iOS (dibuat sebagai indikasi visual)
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.textLight, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_forward, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Swipe',
                    style: AppStyles.metricTitle.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

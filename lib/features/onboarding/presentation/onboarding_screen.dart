import 'package:flutter/material.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(),
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _buildPage(
                title: 'Lean Health',
                subtitle: 'Aplikasi Analisis Efisiensi Layanan Rumah Sakit.',
                illustration: Icons.health_and_safety,
              ),
              _buildPage(
                title: 'Otomatisasi Lean',
                subtitle:
                    'Mengidentifikasi bottleneck secara real-time untuk pelayanan yang lebih cepat.',
                illustration: Icons.local_hospital_outlined,
              ),
              _buildPage(
                title: 'Mulai Perekaman',
                subtitle:
                    'Perekaman waktu dimulai saat QR Code pasien dipindai.',
                illustration: Icons.qr_code_scanner,
              ),
            ],
          ),

          Align(
            alignment: const Alignment(0, 0.85),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_numPages, (index) => _buildDot(index)),
            ),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 30, bottom: 40),
              child: FloatingActionButton(
                backgroundColor: AppColors.primaryBlue,
                onPressed: () {
                  if (_currentPage < _numPages - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, '/scan-id');
                  }
                },
                child: Icon(
                  _currentPage < _numPages - 1
                      ? Icons.arrow_forward
                      : Icons.check,
                  color: AppColors.cardSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required IconData illustration,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            color: AppColors.lightGreyBackground,
            child: Center(
              child: Icon(illustration, size: 80, color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: AppStyles.headline1.copyWith(color: AppColors.primaryBlue),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? AppColors.primaryBlue
            : AppColors.textLight.withAlpha(127),
      ),
    );
  }
}

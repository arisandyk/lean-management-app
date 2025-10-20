import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart'; // Import AppStyles

class RecommendationCard extends StatelessWidget {
  final String recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(FontAwesomeIcons.lightbulb, color: AppColors.accentTeal),
                SizedBox(width: 8),
                Text(
                  'Rekomendasi Solusi (Rule-Based)',
                  // Perbaikan: Menggunakan AppStyles
                  style: AppStyles.headline2,
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.lightGreyBackground),
            Text(
              recommendation,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

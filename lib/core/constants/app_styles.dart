import 'package:flutter/material.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';

class AppStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle metricValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );

  static const TextStyle metricTitle = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );
}
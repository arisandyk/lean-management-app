import 'package:flutter/material.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext build) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: AppStyles.metricTitle),
              ],
            ),
            Text(
              value,
              style: AppStyles.metricValue.copyWith(fontSize: 24, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';

class BottleneckBarChart extends StatelessWidget {
  final Map<String, double> chartData;

  const BottleneckBarChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final labels = chartData.keys.toList();
    final primaryColor = AppColors.primaryBlue;

    final barGroups = labels.asMap().entries.map((entry) {
      int index = entry.key;
      String key = entry.value;
      double value = chartData[key]!;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: value >= 30 ? AppColors.dangerRed : primaryColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
        showingTooltipIndicators: const [0],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData group) {
              return Colors.black.withAlpha(204);
            },

            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${labels[groupIndex]}: ${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),

        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Text(
                  labels[value.toInt()],
                  style: AppStyles.metricTitle.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 20,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Text('${value.toInt()}%', style: AppStyles.metricTitle),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),

        barGroups: barGroups,
      ),
    );
  }
}

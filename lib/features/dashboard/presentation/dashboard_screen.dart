import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lean_health_apps/core/services/data_service.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/utils/helper_functions.dart';
import 'package:lean_health_apps/features/dashboard/models/analysis_result.dart';
import 'package:lean_health_apps/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:lean_health_apps/features/dashboard/presentation/widgets/chart_widget.dart';
import 'package:lean_health_apps/features/dashboard/presentation/widgets/recommendation_card.dart';
import 'package:lean_health_apps/features/patient_log/models/patient_log.model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LeanDataService _dataService = LeanDataService();

  // Logika Rule-Based
  String _getRecommendation(Map<String, double> chartData) {
    // Cari tahapan dengan persentase kontribusi tertinggi
    final bottleneck = chartData.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    if (bottleneck.key == 'Pendft' && bottleneck.value >= 30) {
      return 'Waktu tunggu Pendaftaran tinggi (${bottleneck.value.toStringAsFixed(0)}%). Tindakan: Segera alihkan staf pendaftaran atau terapkan *self-check-in* (biaya rendah).';
    } else if (bottleneck.key == 'Apotek' && bottleneck.value >= 30) {
      return 'Waktu tunggu Apotek tinggi (${bottleneck.value.toStringAsFixed(0)}%). Tindakan: Re-evaluasi *workflow* peracikan obat atau implementasikan notifikasi SMS saat obat siap (biaya rendah).';
    } else {
      return 'Kinerja Layanan Cukup Efisien. Pertahankan monitoring dan fokus pada pengurangan waktu proses di stase Konsultasi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan ValueListenableBuilder untuk mendengarkan perubahan Hive secara real-time
    return ValueListenableBuilder<Box<PatientLog>>(
      valueListenable: _dataService.patientLogsListener,
      builder: (context, box, child) {
        // Panggil analisis setiap kali data di Hive berubah
        final AnalysisResult analysisData = _dataService.analyzeData();

        final chartData = analysisData.bottleneckChart;
        final totalAvgTime = analysisData.avgTotalTime;
        final patientCount = analysisData.servedCount;

        // Membangun UI Dashboard
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Lean Health Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bug_report), // Tombol Debug
                onPressed: () => Navigator.pushNamed(context, '/debug'),
                tooltip: 'Lihat Database (Debug)',
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow), // Tombol Start Perekaman
                onPressed: () => Navigator.pushNamed(context, '/input'),
                tooltip: 'Mulai Perekaman Waktu',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Kinerja Hari Ini (Data Real-time)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 15),

                _buildSummaryGrid(totalAvgTime, patientCount, analysisData),
                const SizedBox(height: 25),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kontribusi Bottleneck (Persentase Waktu)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 250,
                          child: BottleneckBarChart(chartData: chartData),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                RecommendationCard(
                  recommendation: _getRecommendation(chartData),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryGrid(
    double totalAvgTime,
    int patientCount,
    AnalysisResult data,
  ) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.0,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricCard(
          title: 'Total Waktu Tunggu',
          value: formatTimeInMinutes(totalAvgTime),
          color: AppColors.dangerRed,
          icon: FontAwesomeIcons.hourglassHalf,
        ),
        MetricCard(
          title: 'Pasien Selesai Layanan',
          value: '$patientCount',
          color: AppColors.infoBlue,
          icon: FontAwesomeIcons.users,
        ),
        MetricCard(
          title: 'Avg. Tunggu Pendaftaran',
          value: formatTimeInMinutes(data.avgPendaftaran),
          color: AppColors.warningOrange,
          icon: FontAwesomeIcons.userPen,
        ),
        MetricCard(
          title: 'Avg. Proses Konsultasi',
          value: formatTimeInMinutes(data.avgKonsultasi),
          color: AppColors.warningOrange,
          icon: FontAwesomeIcons.userDoctor,
        ),
        MetricCard(
          title: 'Avg. Tunggu Apotek',
          value: formatTimeInMinutes(data.avgApotek),
          color: AppColors.successGreen,
          icon: FontAwesomeIcons.pills,
        ),
      ],
    );
  }
}

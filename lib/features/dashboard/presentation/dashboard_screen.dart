import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lean_health_apps/core/services/data_service.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';
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

  String _timeFilter = 'ALL';
  final Map<String, String> _filterOptions = const {
    'ALL': 'Semua Data',
    'TODAY': 'Hari Ini',
    'LAST_7_DAYS': '7 Hari Terakhir',
  };

  @override
  void initState() {
    super.initState();
  }

  String _getRecommendation(Map<String, double> chartData) {
    if (chartData.values.every((v) => v == 0)) {
      return 'Tidak ada data selesai untuk dianalisis. Coba selesaikan minimal 3 pasien.';
    }

    final bottleneck = chartData.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final value = bottleneck.value.toStringAsFixed(0);

    if (bottleneck.key == 'Pendft' && bottleneck.value >= 40) {
      return 'TINGGI ($value%): Pendaftaran adalah bottleneck utama. Tindakan: 1. Terapkan sistem janji temu online. 2. Alihkan satu staf ke triage pendaftaran pada jam sibuk (08:00-10:00). 3. Pertimbangkan self-check-in melalui kios.';
    } else if (bottleneck.key == 'Pendft' && bottleneck.value >= 30) {
      return 'SEDANG ($value%): Pendaftaran membutuhkan perhatian. Tindakan: Gunakan satu loket khusus untuk pasien lama (administrasi cepat) dan edukasi pasien tentang kelengkapan dokumen.';
    } else if (bottleneck.key == 'Apotek' && bottleneck.value >= 40) {
      return 'TINGGI ($value%): Apotek adalah bottleneck utama. Tindakan: 1. Terapkan sistem notifikasi SMS ke pasien saat obat siap. 2. Standardisasi proses peracikan untuk obat umum (prediksi stok). 3. Pisahkan loket penyerahan dan pembayaran.';
    } else if (bottleneck.key == 'Apotek' && bottleneck.value >= 30) {
      return 'SEDANG ($value%): Apotek perlu dioptimalkan. Tindakan: Lakukan pelatihan cross-training pada staf untuk membantu pengemasan obat saat jam puncak.';
    } else {
      return 'Kinerja Layanan Cukup Efisien. Pertahankan monitoring dan fokus pada pengurangan waktu proses di stase Konsultasi.';
    }
  }

  Widget _buildActivePatientsList(List<PatientLog> activePatients) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled, color: AppColors.warningOrange),
              const SizedBox(width: 8),
              Text(
                'Pasien Dalam Proses (${activePatients.length})',
                style: AppStyles.headline2.copyWith(
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(),
          if (activePatients.isEmpty)
            const Text(
              'Tidak ada pasien yang sedang diproses saat ini.',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else
            ...activePatients.map(
              (log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Text(
                      log.id,
                      style: AppStyles.metricValue.copyWith(
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${log.namaPasien} - Status: ${log.stageStatus.replaceAll('_', ' ')}',
                        style: AppStyles.metricTitle.copyWith(
                          color: AppColors.textDark,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: Text(
              'Arsawan Health',
              style: AppStyles.headline1.copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Dashboard (Home)'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan Pasien'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/scan-id');
            },
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('QR Generator'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/qr');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Riwayat Pasien'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/debug');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<PatientLog>>(
      valueListenable: _dataService.patientLogsListener,
      builder: (context, box, child) {
        final AnalysisResult analysisData = _dataService.analyzeData(
          filter: _timeFilter,
        );
        final List<PatientLog> activePatients = _dataService
            .getActivePatients();

        final chartData = analysisData.bottleneckChart;
        final totalAvgTime = analysisData.avgTotalTime;
        final patientCount = analysisData.servedCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Lean Health Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primaryBlue,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeFilter,
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppColors.cardSurface,
                    ),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                    dropdownColor: AppColors.cardSurface,
                    items: _filterOptions.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _timeFilter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivePatientsList(activePatients),
                const SizedBox(height: 16),

                Text('Analisis Durasi Layanan', style: AppStyles.headline1),
                Text(
                  'Filter: ${_filterOptions[_timeFilter]}',
                  style: AppStyles.metricTitle.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 10),

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
      childAspectRatio: 2.1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
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

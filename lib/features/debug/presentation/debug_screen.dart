import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';
import 'package:lean_health_apps/core/services/data_service.dart';
import 'package:lean_health_apps/features/patient_log/models/patient_log.model.dart';
import 'package:lean_health_apps/core/utils/helper_functions.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LeanDataService dataService = LeanDataService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isi Database (Hive)'),
        backgroundColor: AppColors.dangerRed,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final currentContext = context;
              await dataService.clearAllLogs();
              if (currentContext.mounted) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Semua Data Pasien TELAH DIHAPUS!'),
                  ),
                );
              }
            },
            tooltip: 'Hapus Semua Data',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.pushNamed(context, '/qr'),
            tooltip: 'Generate QR Codes',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<PatientLog>>(
        valueListenable: dataService.patientLogsListener,
        builder: (context, box, child) {
          final List<PatientLog> logs = dataService.getAllPatientLogs();

          if (logs.isEmpty) {
            return Center(
              child: Text(
                'Database Kosong. Silakan catat waktu dari Home Screen.',
                style: AppStyles.metricTitle.copyWith(fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogCard(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(PatientLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'ID: ${log.id} - ${log.namaPasien}',
          style: AppStyles.headline2.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          'Status: ${log.stageStatus}',
          style: TextStyle(
            color: log.endTimeObat != null
                ? AppColors.successGreen
                : AppColors.warningOrange,
          ),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeDetail(
                  'Pendaftaran',
                  log.startTimePendaftaran,
                  log.endTimePendaftaran,
                ),
                _buildTimeDetail(
                  'Konsultasi',
                  log.startTimeKonsultasi,
                  log.endTimeKonsultasi,
                ),
                _buildTimeDetail('Obat', log.startTimeObat, log.endTimeObat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetail(String label, DateTime? start, DateTime? end) {
    final bool isCompleted = start != null && end != null;
    final double duration = isCompleted
        ? PatientLog(
            id: '',
            namaPasien: '',
            stageStatus: '',
          ).calculateDuration(start, end)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: AppStyles.metricTitle.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mulai: ${start?.toIso8601String().substring(11, 19) ?? 'N/A'}',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                'Selesai: ${end?.toIso8601String().substring(11, 19) ?? 'N/A'}',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                'Durasi: ${formatTimeInMinutes(duration)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isCompleted
                      ? AppColors.primaryBlue
                      : AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

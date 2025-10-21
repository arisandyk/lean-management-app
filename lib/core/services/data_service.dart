import 'package:hive_flutter/hive_flutter.dart';
import 'package:lean_health_apps/features/patient_log/models/patient_log.model.dart';
import 'package:lean_health_apps/features/dashboard/models/analysis_result.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class LeanDataService {
  final Box<PatientLog> _patientBox = Hive.box<PatientLog>('patientLogs');
  static final LeanDataService _instance = LeanDataService._internal();

  factory LeanDataService() {
    return _instance;
  }

  LeanDataService._internal();

  ValueListenable<Box<PatientLog>> get patientLogsListener =>
      _patientBox.listenable();

  Future<void> createPatientLog(String id, String nama) async {
    final newLog = PatientLog(
      id: id,
      namaPasien: nama,
      stageStatus: 'PILIH_PENDAFTARAN',
    );
    await _patientBox.put(id, newLog);
  }

  PatientLog? getPatientLog(String id) {
    return _patientBox.get(id);
  }

  Future<void> updatePatientLog(PatientLog log) async {
    await log.save();
  }

  List<PatientLog> getAllPatientLogs() {
    return _patientBox.values.toList();
  }

  Future<void> clearAllLogs() async {
    await _patientBox.clear();
  }

  List<PatientLog> getActivePatients() {
    return _patientBox.values.where((log) {
      return log.stageStatus != 'SELESAI_LAYANAN';
    }).toList();
  }

  List<PatientLog> getFilteredLogs({String filter = 'ALL'}) {
    final allLogs = _patientBox.values.toList();
    final now = DateTime.now();

    return allLogs.where((log) {
      if (log.startTimePendaftaran == null) return false;

      final logDate = log.startTimePendaftaran!;

      if (filter == 'TODAY') {
        return logDate.year == now.year &&
            logDate.month == now.month &&
            logDate.day == now.day;
      } else if (filter == 'LAST_7_DAYS') {
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return logDate.isAfter(sevenDaysAgo);
      } else {
        // 'ALL'
        return true;
      }
    }).toList();
  }

  AnalysisResult analyzeData({String filter = 'ALL'}) {
    final allFilteredLogs = getFilteredLogs(filter: filter);

    final completedLogs = allFilteredLogs
        .where((log) => log.endTimeObat != null)
        .toList();

    if (completedLogs.isEmpty) {
      return AnalysisResult(
        servedCount: 0,
        avgTotalTime: 0,
        avgPendaftaran: 0,
        avgKonsultasi: 0,
        avgApotek: 0,
        bottleneckChart: {'Pendft': 0.0, 'Konsul': 0.0, 'Apotek': 0.0},
      );
    }

    double totalPendaftaran = 0;
    double totalKonsultasi = 0;
    double totalApotek = 0;
    final int completedPatientsCount = completedLogs.length;

    for (var log in completedLogs) {
      if (log.startTimePendaftaran != null && log.endTimePendaftaran != null) {
        totalPendaftaran += log.calculateDuration(
          log.startTimePendaftaran,
          log.endTimePendaftaran,
        );
      }
      if (log.startTimeKonsultasi != null && log.endTimeKonsultasi != null) {
        totalKonsultasi += log.calculateDuration(
          log.startTimeKonsultasi,
          log.endTimeKonsultasi,
        );
      }
      if (log.startTimeObat != null && log.endTimeObat != null) {
        totalApotek += log.calculateDuration(
          log.startTimeObat,
          log.endTimeObat,
        );
      }
    }

    final avgPendaftaran = totalPendaftaran / completedPatientsCount;
    final avgKonsultasi = totalKonsultasi / completedPatientsCount;
    final avgApotek = totalApotek / completedPatientsCount;
    final totalAvg = avgPendaftaran + avgKonsultasi + avgApotek;

    final totalTime = avgPendaftaran + avgKonsultasi + avgApotek;

    final chartData = totalTime > 0.001
        ? {
            'Pendft': (avgPendaftaran / totalTime) * 100,
            'Konsul': (avgKonsultasi / totalTime) * 100,
            'Apotek': (avgApotek / totalTime) * 100,
          }
        : {'Pendft': 33.3, 'Konsul': 33.3, 'Apotek': 33.3};

    return AnalysisResult(
      servedCount: completedPatientsCount,
      avgTotalTime: totalAvg,
      avgPendaftaran: avgPendaftaran,
      avgKonsultasi: avgKonsultasi,
      avgApotek: avgApotek,
      bottleneckChart: chartData,
    );
  }
}

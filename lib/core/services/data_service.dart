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

  // Getter untuk mendengarkan perubahan pada Box secara real-time (digunakan di Dashboard)
  ValueListenable<Box<PatientLog>> get patientLogsListener => _patientBox.listenable();

  // ------------------------------------------
  // CRUD Pasien
  // ------------------------------------------

  /// Membuat log pasien baru saat Mulai Pendaftaran pertama kali.
  Future<void> createPatientLog(String id, String nama) async {
    final newLog = PatientLog(
      id: id,
      namaPasien: nama,
      stageStatus: 'PILIH_PENDAFTARAN',
    );
    // Hive menggunakan ID pasien sebagai key (unique)
    await _patientBox.put(id, newLog);
  }

  /// Mengambil data log pasien berdasarkan ID.
  PatientLog? getPatientLog(String id) {
    return _patientBox.get(id);
  }

  /// Memperbarui dan menyimpan objek PatientLog yang sudah dimodifikasi (update status/time).
  Future<void> updatePatientLog(PatientLog log) async {
    await log.save(); // Method save() berasal dari HiveObject
  }

  /// Mengambil semua log pasien yang tersimpan di Hive (untuk debugging).
  List<PatientLog> getAllPatientLogs() {
    return _patientBox.values.toList();
  }

  /// Membersihkan semua data di Box (untuk debugging).
  Future<void> clearAllLogs() async {
    await _patientBox.clear();
  }

  // ------------------------------------------
  // Analisis Lean Management
  // ------------------------------------------

  /// Menghitung metrik Lean berdasarkan data pasien yang telah selesai dilayani.
  AnalysisResult analyzeData() {
    // Hanya hitung log yang sudah selesai sepenuhnya (endTimeObat != null)
    final completedLogs = _patientBox.values.where((log) => log.endTimeObat != null).toList();

    if (completedLogs.isEmpty) {
      return AnalysisResult(
        servedCount: 0, avgTotalTime: 0, avgPendaftaran: 0, avgKonsultasi: 0, avgApotek: 0,
        bottleneckChart: {'Pendft': 0.0, 'Konsul': 0.0, 'Apotek': 0.0},
      );
    }

    double totalPendaftaran = 0;
    double totalKonsultasi = 0;
    double totalApotek = 0;
    final int completedPatientsCount = completedLogs.length;

    for (var log in completedLogs) {
      // Pastikan semua start/end time tidak null sebelum menghitung
      if (log.startTimePendaftaran != null && log.endTimePendaftaran != null) {
        totalPendaftaran += log.calculateDuration(log.startTimePendaftaran, log.endTimePendaftaran);
      }
      if (log.startTimeKonsultasi != null && log.endTimeKonsultasi != null) {
        totalKonsultasi += log.calculateDuration(log.startTimeKonsultasi, log.endTimeKonsultasi);
      }
      if (log.startTimeObat != null && log.endTimeObat != null) {
        totalApotek += log.calculateDuration(log.startTimeObat, log.endTimeObat);
      }
    }

    // Perhitungan Rata-Rata
    final avgPendaftaran = totalPendaftaran / completedPatientsCount;
    final avgKonsultasi = totalKonsultasi / completedPatientsCount;
    final avgApotek = totalApotek / completedPatientsCount;
    final totalAvg = avgPendaftaran + avgKonsultasi + avgApotek;

    // Data untuk Bar Chart (Persentase Kontribusi Bottleneck)
    final totalTime = avgPendaftaran + avgKonsultasi + avgApotek;

    // Cegah pembagian oleh nol.
    final chartData = totalTime > 0.001 ? {
      'Pendft': (avgPendaftaran / totalTime) * 100,
      'Konsul': (avgKonsultasi / totalTime) * 100,
      'Apotek': (avgApotek / totalTime) * 100,
    } : {'Pendft': 33.3, 'Konsul': 33.3, 'Apotek': 33.3}; // Nilai default jika total waktu 0

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
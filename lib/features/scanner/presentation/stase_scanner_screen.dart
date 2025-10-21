import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';
import 'package:lean_health_apps/core/services/data_service.dart';
import 'package:lean_health_apps/features/patient_log/models/patient_log.model.dart';
import 'package:lean_health_apps/features/scanner/models/scan_data_model.dart';
import 'dart:async';

class StaseScannerScreen extends StatefulWidget {
  final ScanData patientData;
  const StaseScannerScreen({super.key, required this.patientData});

  @override
  State<StaseScannerScreen> createState() => _StaseScannerScreenState();
}

class _StaseScannerScreenState extends State<StaseScannerScreen> {
  final LeanDataService _dataService = LeanDataService();
  MobileScannerController cameraController = MobileScannerController();

  PatientLog? _currentLog;
  String _activeStage = '';
  String _currentStatus = 'Memuat data pasien...';

  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isProcessingScan = false;

  // Stase mapping
  final Map<String, String> staseMap = const {
    'PENDAFTARAN': 'Pendaftaran',
    'KONSULTASI': 'Konsultasi',
    'APOTEK': 'Obat',
  };

  @override
  void initState() {
    super.initState();
    _initializePatientLog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  void _initializePatientLog() async {
    final patientId = widget.patientData.patientId;
    _currentLog = _dataService.getPatientLog(patientId);

    // Jika log belum ada (harus dibuat di ID Scanner, tapi jaga-jaga)
    if (_currentLog == null) {
      await _dataService.createPatientLog(
        patientId,
        widget.patientData.patientName,
      );
      _currentLog = _dataService.getPatientLog(patientId);
    }

    // Cek apakah ada stage yang sedang berjalan untuk melanjutkan timer
    _checkActiveStageAndTimer();
    setState(() {});
  }

  void _checkActiveStageAndTimer() {
    if (_currentLog == null) return;

    // Menentukan stage aktif dan waktu mulai untuk melanjutkan timer
    DateTime? startTime;
    String status = _currentLog!.stageStatus;

    if (status.contains('MENUNGGU_KONSULTASI') &&
        _currentLog!.startTimePendaftaran != null) {
      // Pasien sedang dalam waktu tunggu Pendaftaran (proses dimulai di ID Scanner)
      _activeStage = 'Pendaftaran';
      startTime = _currentLog!.startTimePendaftaran;
    } else if (status.contains('SEDANG_KONSULTASI') &&
        _currentLog!.startTimeKonsultasi != null) {
      _activeStage = 'Konsultasi';
      startTime = _currentLog!.startTimeKonsultasi;
    } else if (status.contains('PROSES_OBAT') &&
        _currentLog!.startTimeObat != null) {
      _activeStage = 'Obat';
      startTime = _currentLog!.startTimeObat;
    } else {
      _activeStage = '';
      _stopTimer();
    }

    _currentStatus = status;

    if (startTime != null && _activeStage.isNotEmpty) {
      _startTimer(startTime);
    }
  }

  void _startTimer(DateTime startTime) {
    _timer?.cancel();
    _elapsedTime = DateTime.now().difference(startTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(startTime);
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _elapsedTime = Duration.zero;
  }

  // -----------------------------------------------------
  // LOGIC SCANNING
  // -----------------------------------------------------

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessingScan || _currentLog == null) return;

    final String? rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    // Nonaktifkan scanner dan mulai proses
    _isProcessingScan = true;
    cameraController.stop();

    final parts = rawValue.split(':');
    final type = parts[0];
    final staseKey = parts.length > 1 ? parts[1] : '';
    final now = DateTime.now();

    if (type == 'STASE') {
      final currentStatus = _currentLog!.stageStatus;
      String nextAction = '';

      // Tentukan aksi berdasarkan status pasien saat ini dan QR Stase yang di-scan
      if (currentStatus == 'MENUNGGU_KONSULTASI' && staseKey == 'KONSULTASI') {
        // Aksi 1: Selesai Pendaftaran dan Mulai Konsultasi
        _currentLog!.endTimePendaftaran = now;
        _currentLog!.startTimeKonsultasi = now;
        _currentLog!.stageStatus = 'SEDANG_KONSULTASI';
        _activeStage = staseMap[staseKey]!;
        _stopTimer();
        _startTimer(now);
        nextAction = 'Selesai Pendaftaran & Mulai Konsultasi';
      } else if (currentStatus == 'SEDANG_KONSULTASI' && staseKey == 'APOTEK') {
        // Aksi 2: Selesai Konsultasi dan Mulai Obat
        _currentLog!.endTimeKonsultasi = now;
        _currentLog!.startTimeObat = now;
        _currentLog!.stageStatus = 'PROSES_OBAT';
        _activeStage = staseMap[staseKey]!;
        _stopTimer();
        _startTimer(now);
        nextAction = 'Selesai Konsultasi & Mulai Obat';
      } else if (currentStatus == 'PROSES_OBAT' && staseKey == 'APOTEK') {
        // Aksi 3: Selesai Obat (Layanan Komplit)
        _currentLog!.endTimeObat = now;
        _currentLog!.stageStatus = 'SELESAI_LAYANAN';
        _activeStage = '';
        _stopTimer();
        nextAction = 'Layanan Komplit (Data Dikirim ke Dashboard)';
      } else {
        _showSnackbar(
          'QR Stase tidak sesuai dengan alur ${currentStatus}!',
          false,
        );
        _resumeScanningAfterDelay();
        return;
      }

      await _dataService.updatePatientLog(_currentLog!);
      _showSnackbar(nextAction, true);

      // Jika Layanan Selesai, arahkan ke Dashboard
      if (_currentLog!.stageStatus == 'SELESAI_LAYANAN') {
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      _showSnackbar(
        'QR Code yang discan BUKAN QR Stase. Harap Scan QR Stase di lokasi!',
        false,
      );
    }

    _resumeScanningAfterDelay();
  }

  void _resumeScanningAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _isProcessingScan = false;
        cameraController.start();
        setState(() {});
      }
    });
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.accentTeal : AppColors.dangerRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // -----------------------------------------------------
  // UI
  // -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Stase Layanan'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              // Menggunakan Stack untuk Overlay
              children: [
                MobileScanner(
                  // Hapus properti overlay yang usang
                  controller: cameraController,
                  onDetect: _handleScan,
                ),
                // CUSTOM OVERLAY SEBAGAI WIDGET DI ATAS MOBILESCANNER
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessingScan
                            ? AppColors.dangerRed
                            : AppColors.accentTeal,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isProcessingScan ? 'MEMPROSES...' : 'SCAN QR STASE',
                      style: AppStyles.headline2.copyWith(
                        color: AppColors.cardSurface,
                        backgroundColor: AppColors.textDark.withAlpha(153),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: AppColors.cardSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PASIEN: ${widget.patientData.patientId} - ${widget.patientData.patientName}',
                    style: AppStyles.headline2.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'STATUS: ${_currentStatus}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _currentLog?.endTimeObat != null
                          ? AppColors.successGreen
                          : AppColors.warningOrange,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Waktu Berjalan: ${TimerUtils.formatDuration(_elapsedTime)}',
                    style: AppStyles.headline1.copyWith(
                      fontSize: 30,
                      color: AppColors.dangerRed,
                    ),
                  ),
                  Text(
                    'Instruksi: Scan QR Stase ${staseMap[_activeStage] ?? 'Pendaftaran'} untuk melanjutkan alur.',
                    style: AppStyles.metricTitle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tambahkan Utils Helper baru untuk Timer Formatting (untuk digunakan di sini)
class TimerUtils {
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}

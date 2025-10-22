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
    cameraController.stop();
    cameraController.dispose();
    super.dispose();
  }

  void _initializePatientLog() async {
    final patientId = widget.patientData.patientId;
    _currentLog = _dataService.getPatientLog(patientId);

    if (_currentLog == null) {
      await _dataService.createPatientLog(
        patientId,
        widget.patientData.patientName,
      );
      _currentLog = _dataService.getPatientLog(patientId);
    }

    _checkActiveStageAndTimer();
    setState(() {});
  }

  void _checkActiveStageAndTimer() {
    if (_currentLog == null) return;

    DateTime? startTime;
    String status = _currentLog!.stageStatus;

    if (status == 'MENUNGGU_KONSULTASI' &&
        _currentLog!.startTimePendaftaran != null) {
      _activeStage = 'Pendaftaran';
      startTime = _currentLog!.startTimePendaftaran;
    } else if (status == 'SEDANG_KONSULTASI' &&
        _currentLog!.startTimeKonsultasi != null) {
      _activeStage = 'Konsultasi';
      startTime = _currentLog!.startTimeKonsultasi;
    } else if (status == 'PROSES_OBAT' && _currentLog!.startTimeObat != null) {
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

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessingScan || _currentLog == null) return;

    final String? rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessingScan = true;
    cameraController.stop();

    final parts = rawValue.split(':');
    final type = parts[0];
    final staseKey = parts.length > 1 ? parts[1] : '';
    final now = DateTime.now();

    if (type == 'STASE') {
      final currentStatus = _currentLog!.stageStatus;
      String nextAction = '';

      if (currentStatus == 'PILIH_PENDAFTARAN' && staseKey == 'PENDAFTARAN') {
        _currentLog!.startTimePendaftaran = now;
        _currentLog!.stageStatus = 'MENUNGGU_KONSULTASI';
        _activeStage = staseMap[staseKey]!;
        _startTimer(now);
        nextAction = 'Perekaman DIMULAI (Pendaftaran)';
      } else if (currentStatus == 'MENUNGGU_KONSULTASI' &&
          staseKey == 'KONSULTASI') {
        _currentLog!.endTimePendaftaran = now;
        _currentLog!.startTimeKonsultasi = now;
        _currentLog!.stageStatus = 'SEDANG_KONSULTASI';
        _activeStage = staseMap[staseKey]!;
        _stopTimer();
        _startTimer(now);
        nextAction = 'Selesai Pendaftaran & Mulai Konsultasi';
      } else if (currentStatus == 'SEDANG_KONSULTASI' && staseKey == 'APOTEK') {
        _currentLog!.endTimeKonsultasi =
            now;
        _currentLog!.startTimeObat = now;
        _currentLog!.stageStatus = 'PROSES_OBAT';
        _activeStage = staseMap[staseKey]!;
        _stopTimer();
        _startTimer(now);
        nextAction = 'Selesai Konsultasi & Mulai Obat';
      } else if (currentStatus == 'PROSES_OBAT' &&
          staseKey == 'SELESAI_LAYANAN') {
        _currentLog!.endTimeObat = now;
        _currentLog!.stageStatus = 'SELESAI_LAYANAN';
        _activeStage = '';
        _stopTimer();
        nextAction = 'Layanan Komplit (Data Dicatat)';

        await _dataService.updatePatientLog(_currentLog!);

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Layanan Selesai'),
              content: Text(
                'Pasien ${_currentLog!.id} telah menyelesaikan semua tahapan. Data durasi telah dicatat dan siap dianalisis di Dashboard.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                  child: const Text('Lihat Dashboard'),
                ),
              ],
            ),
          );
        }
        return;
      } else {
        _showSnackbar(
          'QR Stase ($staseKey) tidak sesuai dengan alur $currentStatus!',
          false,
          3,
        );
        _resumeScanningAfterDelay(3);
        return;
      }

      await _dataService.updatePatientLog(_currentLog!);
      _showSnackbar(nextAction, true, 3);
      _resumeScanningAfterDelay(3);
    } else {
      _showSnackbar(
        'QR Code yang discan BUKAN QR Stase. Harap Scan QR Stase di lokasi!',
        false,
        3,
      );
      _resumeScanningAfterDelay(3);
    }
  }

  void _resumeScanningAfterDelay(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) {
        _isProcessingScan = false;
        cameraController.start();
        setState(() {});
      }
    });
  }

  void _showSnackbar(String message, bool isSuccess, int seconds) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.accentTeal : AppColors.dangerRed,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/scan-id');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Stase Layanan'),
          backgroundColor: AppColors.primaryBlue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/scan-id'),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _handleScan,
                  ),
                  // CUSTOM OVERLAY
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
                      'STATUS: $_currentStatus',
                      style: TextStyle(
                        fontSize: 16,
                        color: _currentLog?.endTimeObat != null
                            ? AppColors.successGreen
                            : AppColors.warningOrange,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Waktu Berjalan: ${_formatDuration(_elapsedTime)}',
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
      ),
    );
  }
}

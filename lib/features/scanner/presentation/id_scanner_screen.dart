import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';
import 'package:lean_health_apps/core/services/data_service.dart';
import 'package:lean_health_apps/features/patient_log/models/patient_log.model.dart';
import 'package:lean_health_apps/features/scanner/models/scan_data_model.dart';
import 'dart:async';

class IdScannerScreen extends StatefulWidget {
  const IdScannerScreen({super.key});

  @override
  State<IdScannerScreen> createState() => _IdScannerScreenState();
}

class _IdScannerScreenState extends State<IdScannerScreen> {
  final LeanDataService _dataService = LeanDataService();
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessingScan = false;
  String _scanResult = 'Memeriksa Izin Kamera...';
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    // Memastikan controller di-dispose dengan benar saat screen dibuang
    cameraController.stop();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _scanResult = 'Arahkan kamera ke QR Code Gelang Pasien';
      });
      cameraController.start();
    } else {
      setState(() {
        _hasPermission = false;
        _scanResult = 'Akses Kamera DITOLAK. Beri izin di Pengaturan.';
      });
    }
  }

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessingScan) return;

    final List<Barcode> barcodes = capture.barcodes;
    final String? rawValue = barcodes.first.rawValue;

    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessingScan = true;
    cameraController.stop(); // HENTIKAN KAMERA SEGERA

    final parts = rawValue.split(':');
    final type = parts[0];
    final value = parts.length > 1 ? parts[1] : '';

    if (type == 'ID') {
      _processPatientIdScan(value);
    } else {
      _showSnackbar(
        'QR Code tidak valid. Harap scan ID Pasien (ID:...)',
        false,
        4,
      );
      _resumeScanningAfterDelay(2);
    }
  }

  void _processPatientIdScan(String patientId) async {
    PatientLog? currentLog = _dataService.getPatientLog(patientId);

    if (currentLog != null && currentLog.stageStatus == 'SELESAI_LAYANAN') {
      currentLog = null;
    }

    if (currentLog == null) {
      await _dataService.createPatientLog(patientId, 'Pasien $patientId');
      currentLog = _dataService.getPatientLog(patientId);
      _scanResult = 'ID Pasien Ditemukan: $patientId. Mulai Pendaftaran.';
      _showSnackbar('Pasien ID $patientId berhasil diidentifikasi.', true, 2);
    } else {
      _scanResult = 'ID Pasien Ditemukan: $patientId. Lanjutkan sesi.';
      _showSnackbar('Melanjutkan sesi untuk Pasien $patientId.', true, 2);
    }

    final ScanData data = ScanData(
      patientId: patientId,
      patientName: currentLog!.namaPasien,
    );

    // SOLUSI BUG LAYAR PUTIH: Tambahkan delay sangat kecil (50 milidetik)
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      // Navigasi yang memicu dispose() dari screen ini
      Navigator.pushReplacementNamed(context, '/scan-stase', arguments: data);
    }
  }

  void _resumeScanningAfterDelay(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) {
        _isProcessingScan = false;
        if (_hasPermission) cameraController.start();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/onboarding');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Scan ID Pasien',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryBlue,
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // Tampilkan MobileScanner hanya jika izin diberikan
                  if (_hasPermission)
                    MobileScanner(
                      controller: cameraController,
                      onDetect: _handleScan,
                    ),
                  // Tampilkan pesan/tombol jika izin belum diberikan
                  if (!_hasPermission)
                    Center(
                      child: ElevatedButton(
                        onPressed: openAppSettings,
                        child: const Text('Buka Pengaturan Izin Kamera'),
                      ),
                    ),

                  // Custom Overlay
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
                        _isProcessingScan
                            ? 'MEMPROSES ID...'
                            : (_hasPermission
                                  ? 'SCAN GELANG PASIEN'
                                  : 'IZIN DIBUTUHKAN'),
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
                child: Text(
                  _scanResult,
                  style: AppStyles.headline2.copyWith(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

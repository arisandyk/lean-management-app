// lib/features/scanner/presentation/id_scanner_screen.dart (REVISI PERMISSIONS)

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';
import 'package:lean_health_apps/features/scanner/models/scan_data_model.dart';

class IdScannerScreen extends StatefulWidget {
  const IdScannerScreen({super.key});

  @override
  State<IdScannerScreen> createState() => _IdScannerScreenState();
}

class _IdScannerScreenState extends State<IdScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessingScan = false;
  String _scanResult = 'Memeriksa Izin Kamera...';
  bool _hasPermission = false; // State baru untuk izin

  @override
  void initState() {
    super.initState();
    _requestCameraPermission(); // Panggil fungsi permintaan izin
  }

  // Fungsi untuk meminta izin kamera
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _scanResult = 'Arahkan kamera ke QR Code Gelang Pasien';
      });
      // Pastikan controller dihidupkan setelah mendapat izin
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
    cameraController.stop();

    final parts = rawValue.split(':');
    final type = parts[0];
    final value = parts.length > 1 ? parts[1] : '';

    if (type == 'ID') {
      // SUCCESS: ID Pasien Ditemukan
      final ScanData data = ScanData(
        patientId: value,
        patientName: 'Pasien $value',
      );

      setState(() {
        _scanResult = 'ID Pasien Ditemukan: $value';
      });

      // Navigasi
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/scan-stase', arguments: data);
      }
    } else {
      // ERROR: QR Code Bukan ID Pasien
      setState(() {
        _scanResult = 'QR Code tidak valid. Harap scan ID Pasien.';
      });
      _resumeScanningAfterDelay();
    }
  }

  void _resumeScanningAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isProcessingScan = false;
        cameraController.start();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                // Tampilkan pesan jika izin belum diberikan
                if (!_hasPermission)
                  Center(
                    child: ElevatedButton(
                      onPressed: openAppSettings,
                      child: const Text('Buka Pengaturan Izin Kamera'),
                    ),
                  ),

                // Custom Overlay (Gunakan opasitas untuk latar belakang jika scanner tidak aktif)
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
    );
  }
}

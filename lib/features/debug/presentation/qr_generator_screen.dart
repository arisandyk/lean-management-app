import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';

class QrGeneratorScreen extends StatelessWidget {
  const QrGeneratorScreen({super.key});

  final List<Map<String, String>> qrData = const [
    // QR Code untuk Gelang Pasien (ID unik)
    {'title': 'ID Pasien P001 (Gelang)', 'data': 'ID:P001'},
    {'title': 'ID Pasien P002 (Gelang)', 'data': 'ID:P002'},
    // QR Code untuk Stase/Lokasi (ID tetap)
    {'title': 'Stase Pendaftaran', 'data': 'STASE:PENDAFTARAN'},
    {'title': 'Stase Konsultasi Dokter', 'data': 'STASE:KONSULTASI'},
    {'title': 'Stase Pengambilan Obat', 'data': 'STASE:APOTEK'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: qrData.length,
        itemBuilder: (context, index) {
          return _buildQrCard(qrData[index]['title']!, qrData[index]['data']!);
        },
      ),
    );
  }

  Widget _buildQrCard(String title, String data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            // Widget QrImageView dari package qr_flutter
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 150.0,
              gapless: false,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.textDark, // Warna Mata (Kotak Sudut)
              ),
              errorStateBuilder: (cxt, err) {
                return const Center(child: Text('Gagal membuat QR Code!'));
              },
            ),
            const SizedBox(height: 5),
            Text(
              data,
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

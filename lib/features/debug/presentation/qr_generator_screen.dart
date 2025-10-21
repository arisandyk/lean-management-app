import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';

class QrGeneratorScreen extends StatelessWidget {
  const QrGeneratorScreen({super.key});

  final List<Map<String, String>> qrData = const [
    // QR Code untuk Gelang Pasien (ID unik)
    {'title': 'ID Pasien P001 (Gelang)', 'data': 'ID:P001'},
    {'title': 'ID Pasien P002 (Gelang)', 'data': 'ID:P002'},
    {'title': 'ID Pasien P003 (Gelang)', 'data': 'ID:P003'},
    {'title': 'ID Pasien P004 (Gelang)', 'data': 'ID:P004'},
    {'title': 'ID Pasien P005 (Gelang)', 'data': 'ID:P005'},
    {'title': 'ID Pasien P006 (Gelang)', 'data': 'ID:P006'},
    // QR Code untuk Stase/Lokasi (ID tetap)
    {'title': 'Stase PENDAFTARAN', 'data': 'STASE:PENDAFTARAN'},
    {'title': 'Stase KONSULTASI', 'data': 'STASE:KONSULTASI'},
    {'title': 'Stase APOTEK (Obat)', 'data': 'STASE:APOTEK'},
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
          childAspectRatio: 0.75,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 130.0,
              gapless: false,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.textDark,
              ),
              errorStateBuilder: (cxt, err) {
                return const Center(child: Text('Gagal membuat QR Code!'));
              },
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                data,
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

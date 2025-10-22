import 'package:flutter/material.dart';
import 'package:lean_health_apps/core/constants/app_colors.dart';
import 'package:lean_health_apps/core/constants/app_styles.dart';
import 'package:lean_health_apps/core/services/data_service.dart';
import 'package:lean_health_apps/features/patient_log/models/patient_log.model.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LeanDataService _dataService = LeanDataService();
  final TextEditingController _idController = TextEditingController(
    text: 'P001',
  );
  final TextEditingController _nameController = TextEditingController(
    text: 'Pasien Uji',
  );

  PatientLog? _currentLog;
  String _activeStage = '';

  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  final Map<String, String> stages = const {
    'Pendaftaran': 'Pendaftaran',
    'Konsultasi': 'Konsultasi Dokter',
    'Obat': 'Pengambilan Obat',
  };

  @override
  void initState() {
    super.initState();
    _loadActiveLog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadActiveLog() {
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
  // LOGIC TIMER DAN DATABASE
  // -----------------------------------------------------

  Future<void> _handleStageAction(String stage, bool isStart) async {
    if (_currentLog == null) {
      if (isStart) {
        if (_idController.text.isEmpty || _nameController.text.isEmpty) {
          _showSnackbar('ID dan Nama Pasien wajib diisi!', false);
          return;
        }

        if (_dataService.getPatientLog(_idController.text) != null) {
          _showSnackbar(
            'ID Pasien sudah ada. Silakan reset atau gunakan ID lain.',
            false,
          );
          return;
        }

        await _dataService.createPatientLog(
          _idController.text,
          _nameController.text,
        );
        _currentLog = _dataService.getPatientLog(_idController.text);
      } else {
        _showSnackbar(
          'Mulai Pendaftaran harus dilakukan terlebih dahulu!',
          false,
        );
        return;
      }
    }

    final now = DateTime.now();

    // Logika Pencatatan Waktu (Start atau Stop)
    switch (stage) {
      case 'Pendaftaran':
        if (isStart) {
          _currentLog!.startTimePendaftaran = now;
          _currentLog!.stageStatus = 'MENUNGGU_KONSULTASI';
          _activeStage = stage;
          _startTimer(now); // MULAI TIMER
        } else {
          _currentLog!.endTimePendaftaran = now;
          _currentLog!.stageStatus = 'SIAP_KONSULTASI';
          _activeStage = '';
          _stopTimer(); // STOP TIMER
        }
        break;

      case 'Konsultasi':
        if (isStart) {
          _currentLog!.startTimeKonsultasi = now;
          _currentLog!.stageStatus = 'SEDANG_KONSULTASI';
          _activeStage = stage;
          _startTimer(now); // MULAI TIMER
        } else {
          _currentLog!.endTimeKonsultasi = now;
          _currentLog!.stageStatus = 'SIAP_OBAT';
          _activeStage = '';
          _stopTimer(); // STOP TIMER
        }
        break;

      case 'Obat':
        if (isStart) {
          _currentLog!.startTimeObat = now;
          _currentLog!.stageStatus = 'PROSES_OBAT';
          _activeStage = stage;
          _startTimer(now); // MULAI TIMER
        } else {
          _currentLog!.endTimeObat = now;
          _currentLog!.stageStatus = 'SELESAI_LAYANAN';
          _activeStage = '';
          _stopTimer(); // STOP TIMER
        }
        break;
    }

    await _dataService.updatePatientLog(_currentLog!);

    if (_currentLog!.stageStatus == 'SELESAI_LAYANAN') {
      _showSnackbar(
        'Layanan untuk ${_currentLog!.id} Selesai! Data dihitung.',
        true,
      );
      _currentLog = null;
      _idController.clear();
      _nameController.clear();
    } else {
      _showSnackbar(
        'Waktu $stage ${isStart ? 'MULAI' : 'SELESAI'} dicatat!',
        true,
      );
    }

    setState(() {});
  }

  // Helper untuk Snackbar
  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.accentTeal : AppColors.dangerRed,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  String _getButtonLabel(String stage) {
    if (_activeStage == stage) {
      return 'Selesai $stage';
    }
    return 'Mulai $stage';
  }

  bool _isButtonDisabled(String stage) {
    final bool currentlyProcessing = _activeStage.isNotEmpty;

    if (currentlyProcessing && _activeStage != stage) {
      return true;
    }

    if (!currentlyProcessing) {
      if (stage == 'Pendaftaran') {
        return _currentLog != null && _currentLog!.endTimePendaftaran != null;
      }
      if (stage == 'Konsultasi') {
        return _currentLog == null ||
            _currentLog!.endTimePendaftaran == null ||
            _currentLog!.endTimeKonsultasi != null;
      }
      if (stage == 'Obat') {
        return _currentLog == null ||
            _currentLog!.endTimeKonsultasi == null ||
            _currentLog!.endTimeObat != null;
      }
    }

    return false;
  }

  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Simulasi Perekaman Waktu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.pushNamed(context, '/'),
            tooltip: 'Lihat Dashboard',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selamat datang di RS Sehat Selalu Nida',
              style: AppStyles.headline2.copyWith(
                fontSize: 20,
                color: AppColors.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            if (_activeStage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dangerRed),
                ),
                child: Column(
                  children: [
                    Text(
                      'WAKTU BERJALAN (${_activeStage.toUpperCase()})',
                      style: AppStyles.metricTitle.copyWith(
                        color: AppColors.dangerRed,
                      ),
                    ),
                    Text(
                      _formatElapsedTime(_elapsedTime),
                      style: AppStyles.headline1.copyWith(
                        fontSize: 40,
                        color: AppColors.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),

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
                    Text(
                      'Data Pasien',
                      style: AppStyles.headline2.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'ID Pasien (Barcode)',
                      ),
                      enabled: _currentLog == null,
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pasien',
                      ),
                      enabled: _currentLog == null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Status Saat Ini: ${_currentLog?.stageStatus ?? "READY"}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            ...stages.entries.map((entry) {
              final stage = entry.key;
              final isCurrentlyActive = _activeStage == stage;
              final isDisabled = _isButtonDisabled(stage);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: isDisabled
                      ? null
                      : () {
                          _handleStageAction(stage, !isCurrentlyActive);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentlyActive
                        ? AppColors.dangerRed
                        : AppColors.primaryBlue,
                    minimumSize: const Size(double.infinity, 60),
                    elevation: isDisabled ? 0 : 4,
                  ),
                  child: Text(
                    _getButtonLabel(stage),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

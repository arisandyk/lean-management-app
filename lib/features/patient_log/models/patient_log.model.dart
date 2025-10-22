import 'package:hive/hive.dart';

part 'patient_log.model.g.dart';

@HiveType(typeId: 0)
class PatientLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String namaPasien;

  @HiveField(2)
  String stageStatus;

  @HiveField(3)
  DateTime? startTimePendaftaran;

  @HiveField(4)
  DateTime? endTimePendaftaran;

  @HiveField(5)
  DateTime? startTimeKonsultasi;

  @HiveField(6)
  DateTime? endTimeKonsultasi;

  @HiveField(7)
  DateTime? startTimeObat;

  @HiveField(8)
  DateTime? endTimeObat;

  PatientLog({
    required this.id,
    required this.namaPasien,
    required this.stageStatus,
    this.startTimePendaftaran,
    this.endTimePendaftaran,
    this.startTimeKonsultasi,
    this.endTimeKonsultasi,
    this.startTimeObat,
    this.endTimeObat,
  });

  double calculateDuration(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return end.difference(start).inSeconds / 60.0;
    }
    return 0.0;
  }
}

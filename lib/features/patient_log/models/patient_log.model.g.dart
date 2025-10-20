// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_log.model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientLogAdapter extends TypeAdapter<PatientLog> {
  @override
  final int typeId = 0;

  @override
  PatientLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientLog(
      id: fields[0] as String,
      namaPasien: fields[1] as String,
      stageStatus: fields[2] as String,
      startTimePendaftaran: fields[3] as DateTime?,
      endTimePendaftaran: fields[4] as DateTime?,
      startTimeKonsultasi: fields[5] as DateTime?,
      endTimeKonsultasi: fields[6] as DateTime?,
      startTimeObat: fields[7] as DateTime?,
      endTimeObat: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PatientLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.namaPasien)
      ..writeByte(2)
      ..write(obj.stageStatus)
      ..writeByte(3)
      ..write(obj.startTimePendaftaran)
      ..writeByte(4)
      ..write(obj.endTimePendaftaran)
      ..writeByte(5)
      ..write(obj.startTimeKonsultasi)
      ..writeByte(6)
      ..write(obj.endTimeKonsultasi)
      ..writeByte(7)
      ..write(obj.startTimeObat)
      ..writeByte(8)
      ..write(obj.endTimeObat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

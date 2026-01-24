// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerSessionModelAdapter extends TypeAdapter<PrayerSessionModel> {
  @override
  final int typeId = 3;

  @override
  PrayerSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerSessionModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      durationSeconds: fields[2] as int,
      startedAt: fields[3] as DateTime,
      endedAt: fields[4] as DateTime,
      isDeepSession: fields[5] as bool,
      prayersPrayed: fields[6] as int,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerSessionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.endedAt)
      ..writeByte(5)
      ..write(obj.isDeepSession)
      ..writeByte(6)
      ..write(obj.prayersPrayed)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerLogModelAdapter extends TypeAdapter<PrayerLogModel> {
  @override
  final int typeId = 4;

  @override
  PrayerLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerLogModel(
      id: fields[0] as String,
      prayerId: fields[1] as String,
      userId: fields[2] as String?,
      durationMinutes: fields[3] as int,
      actualDurationSeconds: fields[4] as int?,
      prayedAt: fields[5] as DateTime,
      isManual: fields[6] == null ? false : fields[6] as bool,
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      isSynced: fields[9] == null ? false : fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerLogModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.prayerId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.actualDurationSeconds)
      ..writeByte(5)
      ..write(obj.prayedAt)
      ..writeByte(6)
      ..write(obj.isManual)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

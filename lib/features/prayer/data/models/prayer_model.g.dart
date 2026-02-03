// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerModelAdapter extends TypeAdapter<PrayerModel> {
  @override
  final int typeId = 2;

  @override
  PrayerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      requesterName: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
      answeredAt: fields[6] as DateTime?,
      lastPrayedAt: fields[14] as DateTime?,
      status: fields[7] as PrayerStatusModel,
      priority: fields[8] as PrayerPriorityModel,
      legacyIsPrivate: fields[9] == null ? false : fields[9] as bool,
      isLocked: fields[15] == null ? false : fields[15] as bool,
      prayerCount: fields[10] as int,
      tags: (fields[11] as List).cast<String>(),
      testimony: fields[12] as String?,
      scriptureReference: fields[13] as String?,
      testimonyImageUrl: fields[16] as String?,
      isPublicTestimony: fields[17] == null ? false : fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.requesterName)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.answeredAt)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.legacyIsPrivate)
      ..writeByte(10)
      ..write(obj.prayerCount)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.testimony)
      ..writeByte(13)
      ..write(obj.scriptureReference)
      ..writeByte(14)
      ..write(obj.lastPrayedAt)
      ..writeByte(15)
      ..write(obj.isLocked)
      ..writeByte(16)
      ..write(obj.testimonyImageUrl)
      ..writeByte(17)
      ..write(obj.isPublicTestimony);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrayerStatusModelAdapter extends TypeAdapter<PrayerStatusModel> {
  @override
  final int typeId = 0;

  @override
  PrayerStatusModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PrayerStatusModel.active;
      case 1:
        return PrayerStatusModel.answered;
      case 2:
        return PrayerStatusModel.archived;
      default:
        return PrayerStatusModel.active;
    }
  }

  @override
  void write(BinaryWriter writer, PrayerStatusModel obj) {
    switch (obj) {
      case PrayerStatusModel.active:
        writer.writeByte(0);
        break;
      case PrayerStatusModel.answered:
        writer.writeByte(1);
        break;
      case PrayerStatusModel.archived:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerStatusModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrayerPriorityModelAdapter extends TypeAdapter<PrayerPriorityModel> {
  @override
  final int typeId = 1;

  @override
  PrayerPriorityModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PrayerPriorityModel.low;
      case 1:
        return PrayerPriorityModel.medium;
      case 2:
        return PrayerPriorityModel.high;
      case 3:
        return PrayerPriorityModel.urgent;
      default:
        return PrayerPriorityModel.low;
    }
  }

  @override
  void write(BinaryWriter writer, PrayerPriorityModel obj) {
    switch (obj) {
      case PrayerPriorityModel.low:
        writer.writeByte(0);
        break;
      case PrayerPriorityModel.medium:
        writer.writeByte(1);
        break;
      case PrayerPriorityModel.high:
        writer.writeByte(2);
        break;
      case PrayerPriorityModel.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerPriorityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

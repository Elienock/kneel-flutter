// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sermon_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SermonNoteModelAdapter extends TypeAdapter<SermonNoteModel> {
  @override
  final int typeId = 10;

  @override
  SermonNoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SermonNoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      preacher: fields[3] as String,
      mainVerse: fields[4] as String,
      seriesTitle: fields[5] as String?,
      date: fields[6] as DateTime,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      isPinned: fields[9] as bool,
      tags: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SermonNoteModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.preacher)
      ..writeByte(4)
      ..write(obj.mainVerse)
      ..writeByte(5)
      ..write(obj.seriesTitle)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isPinned)
      ..writeByte(10)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SermonNoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

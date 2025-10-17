// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PageProgressAdapter extends TypeAdapter<PageProgress> {
  @override
  final int typeId = 4;

  @override
  PageProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageProgress(
      lastReadPage: fields[0] as int,
      lastReadTime: fields[1] as DateTime,
      totalPagesRead: fields[2] as int,
      pageHistory: (fields[3] as Map?)?.cast<int, DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, PageProgress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lastReadPage)
      ..writeByte(1)
      ..write(obj.lastReadTime)
      ..writeByte(2)
      ..write(obj.totalPagesRead)
      ..writeByte(3)
      ..write(obj.pageHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

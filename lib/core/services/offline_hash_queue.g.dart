// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_hash_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HashQueueItemAdapter extends TypeAdapter<HashQueueItem> {
  @override
  final int typeId = 0;

  @override
  HashQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HashQueueItem(
      filePath: fields[0] as String,
      hashHex: fields[1] as String,
      queuedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HashQueueItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(1)
      ..write(obj.hashHex)
      ..writeByte(2)
      ..write(obj.queuedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HashQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

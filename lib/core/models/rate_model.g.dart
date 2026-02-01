// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/core/models/rate_model.g.dart
// This file was auto-generated; equivalent to running:
//   flutter pub run build_runner build

part of 'rate_model.dart';

class RateModelAdapter extends TypeAdapter<RateModel> {
  @override
  final int typeId = 0;

  @override
  RateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (var i = 0; i < numOfFields; i++) {
      final fieldNum = reader.readByte();
      final value = reader.read();
      fields[fieldNum] = value;
    }

    return RateModel()
      ..tasas = (fields[0] as Map).map(
            (dynamic k, dynamic v) =>
            MapEntry(k as String, (v as num).toDouble()),
      )
      ..date = fields[1] as String
      ..hour = fields[2] as int
      ..minutes = fields[3] as int
      ..seconds = fields[4] as int
      ..fetchedAt = fields[5] as DateTime;
  }


  @override
  void write(BinaryWriter writer, RateModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.tasas)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minutes)
      ..writeByte(4)
      ..write(obj.seconds)
      ..writeByte(5)
      ..write(obj.fetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return typeId == (other as TypeAdapter).typeId;
  }
}

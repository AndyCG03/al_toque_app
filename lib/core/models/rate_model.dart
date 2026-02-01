// lib/core/models/rate_model.dart
import 'package:hive/hive.dart';

part 'rate_model.g.dart';

@HiveType(typeId: 0)
class RateModel extends HiveObject {
  @HiveField(0)
  late Map<String, double> tasas;

  @HiveField(1)
  late String date;

  @HiveField(2)
  late int hour;

  @HiveField(3)
  late int minutes;

  @HiveField(4)
  late int seconds;

  @HiveField(5)
  late DateTime fetchedAt; // timestamp de cuando se guardó localmente

  RateModel();

  factory RateModel.fromJson(Map<String, dynamic> json) {
    final model = RateModel();
    final rawTasas = json['tasas'] as Map<String, dynamic>;
    model.tasas = rawTasas.map((key, value) => MapEntry(key, (value as num).toDouble()));
    model.date = json['date'] as String;
    model.hour = json['hour'] as int;
    model.minutes = json['minutes'] as int;
    model.seconds = json['seconds'] as int;
    model.fetchedAt = DateTime.now();
    return model;
  }

  /// Hora formateada de la respuesta de la API
  String get timeFormatted {
    final h = hour.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Verifica si los datos tienen menos de N horas
  bool isStale({int maxHours = 6}) {
    return DateTime.now().difference(fetchedAt).inHours >= maxHours;
  }
}

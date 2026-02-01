// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tasas_eltoque/app.dart';
import 'package:tasas_eltoque/core/models/rate_model.dart';
import 'package:tasas_eltoque/core/services/local_storage_service.dart';
import 'package:tasas_eltoque/core/theme/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación fija en portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Inicializar Hive ─────────────────────────────────────
  await Hive.initFlutter();

  // Registrar adaptadores generados por hive_generator
  Hive.registerAdapter(RateModelAdapter());

  // ─── Inicializar servicios ────────────────────────────────
  final localStorage = LocalStorageService();
  await localStorage.init();

  final themeCubit = ThemeCubit();
  await themeCubit.init();

  // ─── Lanzar app ───────────────────────────────────────────
  runApp(
    TasasApp(
      themeCubit: themeCubit,
      localStorage: localStorage,
    ),
  );
}
